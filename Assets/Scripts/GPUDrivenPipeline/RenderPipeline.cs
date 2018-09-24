using UnityEngine.Rendering;
using UnityEngine;
using System.Collections.Generic;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Collections;

public unsafe class RenderPipeline : MonoBehaviour
{
    #region STATIC_AREA
    public static ComputeShader gpuFrustumShader;
    public static PipelineBaseBuffer baseBuffer;
    public static ShadowMaskComponent shadMask;
    public static Vector4[] frustumCullingPlanes = new Vector4[6];
    public static Matrix4x4[] cascadeShadowMapVP = new Matrix4x4[4];
    public static Vector4[] shadowCameraPos = new Vector4[4];
    private static bool isInitialized = false;
    public static void Initialize()
    {
        if (isInitialized) return;
        isInitialized = true;
        gpuFrustumShader = Resources.Load<ComputeShader>("GpuFrustumCulling");
        shadMask.shadowmaskMaterial = new Material(Shader.Find("Hidden/ShadowMask"));
        shadMask.afterLightingBuffer = new CommandBuffer();
        TextAsset pointText = Resources.Load<TextAsset>("MapPoints");
        TextAsset infoText = Resources.Load<TextAsset>("MapInfos");
        byte[] pointBytes = pointText.bytes;
        byte[] infoBytes = infoText.bytes;
        Point* points = null;
        ObjectInfo* infos = null;
        int pointLength = 0;
        int infoLength = 0;
        fixed (void* ptr = &pointBytes[0])
        {
            points = (Point*)ptr;
            pointLength = pointBytes.Length / Point.SIZE;
        }
        fixed (void* ptr = &infoBytes[0])
        {
            infos = (ObjectInfo*)ptr;
            infoLength = infoBytes.Length / ObjectInfo.SIZE;
        }
        NativeArray<Point> allPoints = new NativeArray<Point>(pointLength, Allocator.Temp, NativeArrayOptions.UninitializedMemory);
        NativeArray<ObjectInfo> allInfos = new NativeArray<ObjectInfo>(infoLength, Allocator.Temp, NativeArrayOptions.UninitializedMemory);
        void* destination = allPoints.GetUnsafePtr();
        UnsafeUtility.MemCpy(destination, points, pointBytes.Length);
        destination = allInfos.GetUnsafePtr();
        UnsafeUtility.MemCpy(destination, infos, infoBytes.Length);
        PipelineFunctions.Initialize(ref baseBuffer, allPoints, allInfos);
        for (int i = 0; i < cascadeShadowMapVP.Length; ++i)
        {
            cascadeShadowMapVP[i] = Matrix4x4.identity;
        }
        Resources.UnloadAsset(pointText);
        Resources.UnloadAsset(infoText);
        allInfos.Dispose();
        allPoints.Dispose();
    }
    #endregion
    private Camera currentCam;
    private StaticFit staticFit;
    public Material proceduralMaterial;
    private void Awake()
    {
        currentCam = GetComponent<Camera>();
        Initialize();
    }

    private void OnDestroy()
    {
        PipelineFunctions.Dispose(ref baseBuffer);
        shadMask.afterLightingBuffer.Dispose();
        Destroy(shadMask.shadowmaskMaterial);
    }
    private Point GetPoint(Vector3 position)
    {
        Point p;
        p.vertex = position;
        p.texcoord = new Vector2(0, 0);
        p.tangent = new Vector4(1, 0, 0, 1);
        p.normal = Vector3.up;
        return p;
    }

    protected void OnEnable()
    {
        currentCam.AddCommandBuffer(CameraEvent.AfterLighting, shadMask.afterLightingBuffer);
        currentCam.AddCommandBuffer(CameraEvent.AfterGBuffer, baseBuffer.geometryCommand);
    }

    protected void OnDisable()
    {
        currentCam.RemoveCommandBuffer(CameraEvent.AfterLighting, shadMask.afterLightingBuffer);
        currentCam.RemoveCommandBuffer(CameraEvent.AfterGBuffer, baseBuffer.geometryCommand);
        PipelineFunctions.Dispose(ref baseBuffer);
    }

    private void DrawShadow()
    {
        if (SunLight.current == null) return;
        ref ShadowmapSettings settings = ref SunLight.current.settings;
        staticFit.resolution = settings.resolution / 2;
        staticFit.mainCamTrans = currentCam;
        staticFit.shadowCam = SunLight.shadMap.shadowCam;
        PipelineFunctions.UpdateShadowMapState(ref SunLight.shadMap, ref settings);
        DrawCascadeShadow(new Vector2(SunLight.shadMap.shadowCam.nearClipPlane, settings.firstLevelDistance), 0, settings.firstLevelDistance);
        DrawCascadeShadow(new Vector2(settings.firstLevelDistance, settings.secondLevelDistance), 1, settings.secondLevelDistance);
        DrawCascadeShadow(new Vector2(settings.secondLevelDistance, settings.thirdLevelDistance), 2, settings.thirdLevelDistance);
        DrawCascadeShadow(new Vector2(settings.thirdLevelDistance, settings.farestDistance), 3, settings.farestDistance);
        PipelineFunctions.UpdateShadowMaskState(ref shadMask, ref SunLight.shadMap, ref cascadeShadowMapVP, ref shadowCameraPos);
    }

    private void DrawCascadeShadow(Vector2 farClipDistance, int pass, float range)
    {
        ref ShadowmapSettings settings = ref SunLight.current.settings;
        PipelineFunctions.GetfrustumCorners(farClipDistance, ref SunLight.shadMap, currentCam);
        // PipelineFunctions.SetShadowCameraPositionCloseFit(ref SunLight.shadMap, ref settings);
        Matrix4x4 invpVPMatrix;
        staticFit.frustumCorners = SunLight.shadMap.frustumCorners;
        PipelineFunctions.SetShadowCameraPositionStaticFit(ref staticFit, pass, cascadeShadowMapVP, out invpVPMatrix);
        shadowCameraPos[pass] = SunLight.shadMap.shadowCam.transform.position;
        PipelineFunctions.GetCullingPlanes(ref invpVPMatrix, frustumCullingPlanes);
        PipelineFunctions.SetBaseBuffer(ref baseBuffer, gpuFrustumShader, frustumCullingPlanes);
        PipelineFunctions.RunCullDispatching(ref baseBuffer, gpuFrustumShader);
        float* biasList = (float*)UnsafeUtility.AddressOf(ref settings.bias);
        PipelineFunctions.UpdateCascadeState(ref SunLight.shadMap, biasList[pass]);
        PipelineFunctions.RenderShadowProcedural(ref SunLight.shadMap, ref baseBuffer, pass);
    }
    public void OnPreRender()
    {
        PipelineFunctions.SetShaderBuffer(ref baseBuffer);
        DrawShadow();
        Matrix4x4 vp = GL.GetGPUProjectionMatrix(currentCam.projectionMatrix, false) * currentCam.worldToCameraMatrix;
        Matrix4x4 invVP = vp.inverse;
        Shader.SetGlobalMatrix(ShaderIDs._InvVP, invVP);
        PipelineFunctions.GetCullingPlanes(ref invVP, frustumCullingPlanes);
        PipelineFunctions.SetBaseBuffer(ref baseBuffer, gpuFrustumShader, frustumCullingPlanes);
        PipelineFunctions.RunCullDispatching(ref baseBuffer, gpuFrustumShader);
        PipelineFunctions.RenderProceduralCommand(ref baseBuffer, proceduralMaterial);
    }
}
