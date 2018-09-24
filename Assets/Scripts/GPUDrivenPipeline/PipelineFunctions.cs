using System.Collections.Generic;
using UnityEngine;
using Unity.Collections;
using UnityEngine.Rendering;

public unsafe static class PipelineFunctions
{
    public static RenderTargetIdentifier[] gBufferIdentifier = new RenderTargetIdentifier[]
{
        BuiltinRenderTextureType.GBuffer0,
        BuiltinRenderTextureType.GBuffer1,
        BuiltinRenderTextureType.GBuffer2,
        BuiltinRenderTextureType.GBuffer3
};
    const int Vector2IntSize = 8;
    /// <summary>
    /// Get Frustum Planes
    /// </summary>
    /// <param name="invVp"></param> View Projection Inverse Matrix
    /// <param name="cullingPlanes"></param> Culling Planes results
    public static void GetCullingPlanes(ref Matrix4x4 invVp, Vector4[] cullingPlanes)
    {
        Vector3 nearLeftButtom = invVp.MultiplyPoint(new Vector3(-1, -1, 1));
        Vector3 nearLeftTop = invVp.MultiplyPoint(new Vector3(-1, 1, 1));
        Vector3 nearRightButtom = invVp.MultiplyPoint(new Vector3(1, -1, 1));
        Vector3 nearRightTop = invVp.MultiplyPoint(new Vector3(1, 1, 1));
        Vector3 farLeftButtom = invVp.MultiplyPoint(new Vector3(-1, -1, 0));
        Vector3 farLeftTop = invVp.MultiplyPoint(new Vector3(-1, 1, 0));
        Vector3 farRightButtom = invVp.MultiplyPoint(new Vector3(1, -1, 0));
        Vector3 farRightTop = invVp.MultiplyPoint(new Vector3(1, 1, 0));
        Plane plane;
        //Near
        plane = new Plane(nearRightTop, nearRightButtom, nearLeftButtom);
        cullingPlanes[0] = plane.normal;
        cullingPlanes[0].w = plane.distance;
        //Up
        plane = new Plane(farLeftTop, farRightTop, nearRightTop);
        cullingPlanes[1] = plane.normal;
        cullingPlanes[1].w = plane.distance;
        //Down
        plane = new Plane(nearRightButtom, farRightButtom, farLeftButtom);
        cullingPlanes[2] = plane.normal;
        cullingPlanes[2].w = plane.distance;
        //Left
        plane = new Plane(farLeftButtom, farLeftTop, nearLeftTop);
        cullingPlanes[3] = plane.normal;
        cullingPlanes[3].w = plane.distance;
        //Right
        plane = new Plane(farRightButtom, nearRightButtom, nearRightTop);
        cullingPlanes[4] = plane.normal;
        cullingPlanes[4].w = plane.distance;
        //Far
        plane = new Plane(farLeftButtom, farRightButtom, farRightTop);
        cullingPlanes[5] = plane.normal;
        cullingPlanes[5].w = plane.distance;

    }
    /// <summary>
    /// Initialize pipeline buffers
    /// </summary>
    /// <param name="baseBuffer"></param> pipeline base buffer
    public static void Initialize(ref PipelineBaseBuffer baseBuffer, NativeArray<Point> allVertices, NativeArray<ObjectInfo> objectInfos)
    {
        baseBuffer.geometryCommand = new CommandBuffer();
        baseBuffer.clusterBuffer = new ComputeBuffer(objectInfos.Length, ObjectInfo.SIZE);
        baseBuffer.clusterBuffer.SetData(objectInfos);
        baseBuffer.resultBuffer = new ComputeBuffer(objectInfos.Length, PipelineBaseBuffer.UINTSIZE);
        baseBuffer.instanceCountBuffer = new ComputeBuffer(1, PipelineBaseBuffer.INDIRECTSIZE, ComputeBufferType.IndirectArguments);
        baseBuffer.verticesBuffer = new ComputeBuffer(allVertices.Length, Point.SIZE);
        baseBuffer.verticesBuffer.SetData(allVertices);
        baseBuffer.clusterCount = objectInfos.Length;
        baseBuffer.clusterOffset = 0;
    }
    /// <summary>
    /// Get Frustum Corners
    /// </summary>
    /// <param name="distance"></param> target distance range
    /// <param name="shadMap"></param> shadowmap component
    /// <param name="mask"></param> shadowmask component
    public static void GetfrustumCorners(Vector2 distance, ref ShadowMapComponent shadMap, Camera targetCamera)
    {
        //bottom left
        shadMap.frustumCorners[0] = targetCamera.ViewportToWorldPoint(new Vector3(0, 0, distance.x));
        // bottom right
        shadMap.frustumCorners[1] = targetCamera.ViewportToWorldPoint(new Vector3(1, 0, distance.x));
        // top left
        shadMap.frustumCorners[2] = targetCamera.ViewportToWorldPoint(new Vector3(0, 1, distance.x));
        // top right
        shadMap.frustumCorners[3] = targetCamera.ViewportToWorldPoint(new Vector3(1, 1, distance.x));
        //bottom left
        shadMap.frustumCorners[4] = targetCamera.ViewportToWorldPoint(new Vector3(0, 0, distance.y));
        // bottom right
        shadMap.frustumCorners[5] = targetCamera.ViewportToWorldPoint(new Vector3(1, 0, distance.y));
        // top left
        shadMap.frustumCorners[6] = targetCamera.ViewportToWorldPoint(new Vector3(0, 1, distance.y));
        // top right
        shadMap.frustumCorners[7] = targetCamera.ViewportToWorldPoint(new Vector3(1, 1, distance.y));
    }
    /// <summary>
    /// Set Shadowcamera Position
    /// </summary>
    /// <param name="shadMap"></param> Shadowmap component
    /// <param name="settings"></param> Shadowmap Settings
    public static void SetShadowCameraPositionCloseFit(ref ShadowMapComponent shadMap, ref ShadowmapSettings settings)
    {
        Camera shadowCam = shadMap.shadowCam;
        NativeArray<AspectInfo> shadowFrustumPlanes = shadMap.shadowFrustumPlanes;
        AspectInfo info = shadowFrustumPlanes[0];
        info.planeNormal = shadowCam.transform.right;
        shadowFrustumPlanes[0] = info;
        info = shadowFrustumPlanes[1];
        info.planeNormal = shadowCam.transform.up;
        shadowFrustumPlanes[1] = info;
        info = shadowFrustumPlanes[2];
        info.planeNormal = shadowCam.transform.forward;
        shadowFrustumPlanes[2] = info;
        for (int i = 0; i < 3; ++i)
        {
            info = shadowFrustumPlanes[i];
            float least = float.MaxValue;
            float maximum = float.MinValue;
            Vector3 lessPoint = Vector3.zero;
            Vector3 morePoint = Vector3.zero;
            for (int x = 0; x < 8; ++x)
            {
                float dotValue = Vector3.Dot(info.planeNormal, shadMap.frustumCorners[x]);
                if (dotValue < least)
                {
                    least = dotValue;
                    lessPoint = shadMap.frustumCorners[x];
                }
                if (dotValue > maximum)
                {
                    maximum = dotValue;
                    morePoint = shadMap.frustumCorners[x];
                }
            }
            info.size = (maximum - least) / 2f;
            info.inPlanePoint = lessPoint + info.planeNormal * info.size;
            shadowFrustumPlanes[i] = info;
        }
        AspectInfo temp = shadowFrustumPlanes[2];
        temp.size = settings.farestDistance;    //Farest Cascade Distance
        shadowFrustumPlanes[2] = temp;
        Transform tr = shadowCam.transform;
        for (int i = 0; i < 3; ++i)
        {
            info = shadowFrustumPlanes[i];
            float dist = Vector3.Dot(info.inPlanePoint, info.planeNormal) - Vector3.Dot(tr.position, info.planeNormal);
            tr.position += dist * info.planeNormal;
        }
        shadowCam.orthographicSize = shadowFrustumPlanes[1].size;
        shadowCam.aspect = shadowFrustumPlanes[0].size / shadowFrustumPlanes[1].size;
        shadowCam.nearClipPlane = 0;
        shadowCam.farClipPlane = shadowFrustumPlanes[2].size * 2;
        tr.position -= shadowFrustumPlanes[2].size * shadowFrustumPlanes[2].planeNormal;
    }
    public static void SetShadowCameraPositionStaticFit(ref StaticFit fit, int pass, Matrix4x4[] vpMatrices, out Matrix4x4 invShadowVP)
    {
        fit.shadowCam.aspect = 1;
        float range = 0;
        Vector3 averagePos = Vector3.zero;
        foreach(var i in fit.frustumCorners)
        {
            averagePos += i;
        }
        averagePos /= fit.frustumCorners.Length;
        foreach(var i in fit.frustumCorners)
        {
            float dist = Vector3.Distance(averagePos, i);
            if(range < dist)
            {
                range = dist;
            }
        }
        fit.shadowCam.orthographicSize = range;
        float farClipPlane = fit.mainCamTrans.farClipPlane;
        Vector3 targetPosition = averagePos - fit.shadowCam.transform.forward * farClipPlane * 0.5f;
        fit.shadowCam.nearClipPlane = 0;
        fit.shadowCam.farClipPlane = farClipPlane;
        Matrix4x4 shadowVP = vpMatrices[pass];
        invShadowVP = shadowVP.inverse;
        Vector3 ndcPos = shadowVP.MultiplyPoint(targetPosition);
        Vector2 uv = new Vector2(ndcPos.x, ndcPos.y) * 0.5f + new Vector2(0.5f, 0.5f);
        uv.x = (int)(uv.x * fit.resolution + 0.5);
        uv.y = (int)(uv.y * fit.resolution + 0.5);
        uv /= fit.resolution;
        uv = uv * 2f - Vector2.one;
        ndcPos = new Vector3(uv.x, uv.y, ndcPos.z);
        targetPosition = invShadowVP.MultiplyPoint(ndcPos);
        fit.shadowCam.transform.position = targetPosition;
        vpMatrices[pass] = GL.GetGPUProjectionMatrix(fit.shadowCam.projectionMatrix, false) * fit.shadowCam.worldToCameraMatrix;
        invShadowVP = vpMatrices[pass].inverse;
    }
    /// <summary>
    /// Initialize Per frame shadowmap buffers for Shadowmap shader
    /// </summary>
    public static void UpdateShadowMapState(ref ShadowMapComponent comp, ref ShadowmapSettings settings)
    {
        Camera shadowCam = comp.shadowCam;
        Shader.SetGlobalFloat(ShaderIDs._ShadowCamFarClip, shadowCam.farClipPlane);
        Graphics.SetRenderTarget(comp.shadowmapTexture);
        GL.Clear(true, true, Color.white);
        Shader.SetGlobalVector(ShaderIDs._NormalBiases, settings.normalBias);
        Shader.SetGlobalVector(ShaderIDs._ShadowDisableDistance, new Vector4(settings.firstLevelDistance, settings.secondLevelDistance, settings.thirdLevelDistance, settings.farestDistance));
        Shader.SetGlobalVector(ShaderIDs._LightDirection, -comp.light.transform.forward);
        Shader.SetGlobalVector(ShaderIDs._LightFinalColor, comp.light.color * comp.light.intensity);
        Shader.SetGlobalVector(ShaderIDs._SoftParam, settings.cascadeSoftValue / settings.resolution);
    }
    /// <summary>
    /// Initialize per cascade shadowmap buffers
    /// </summary>
    public static void UpdateCascadeState(ref ShadowMapComponent comp, float bias)
    {
        Camera shadowCam = comp.shadowCam;
        Vector4 shadowcamDir = shadowCam.transform.forward;
        shadowcamDir.w = bias;
        Shader.SetGlobalVector(ShaderIDs._ShadowCamDirection, shadowcamDir);
        Matrix4x4 rtVp = GL.GetGPUProjectionMatrix(shadowCam.projectionMatrix, true) * shadowCam.worldToCameraMatrix;
        comp.shadowDepthMaterial.SetMatrix(ShaderIDs._ShadowMapVP, rtVp);
        Shader.SetGlobalVector(ShaderIDs._ShadowCamPos, shadowCam.transform.position);
    }
    /// <summary>
    /// Initialize shadowmask per frame buffers
    /// </summary>
    public static void UpdateShadowMaskState(ref ShadowMaskComponent shadMask, ref ShadowMapComponent shadMap, ref Matrix4x4[] cascadeShadowMapVP, ref Vector4[] shadowCameraPos)
    {
        shadMask.afterLightingBuffer.Clear();
        shadMask.afterLightingBuffer.SetGlobalMatrixArray(ShaderIDs._ShadowMapVPs, cascadeShadowMapVP);
        shadMask.afterLightingBuffer.SetGlobalVectorArray(ShaderIDs._ShadowCamPoses, shadowCameraPos);
        shadMask.afterLightingBuffer.SetGlobalTexture(ShaderIDs._DirShadowMap, shadMap.shadowmapTexture);
        shadMask.afterLightingBuffer.BlitSRT(BuiltinRenderTextureType.CameraTarget, shadMask.shadowmaskMaterial, 0);
    }
    public static void Dispose(ref PipelineBaseBuffer baseBuffer)
    {
        //   baseBuffer.geometryCommand.Dispose();
        baseBuffer.verticesBuffer.Dispose();
        baseBuffer.clusterBuffer.Dispose();
        baseBuffer.instanceCountBuffer.Dispose();
        baseBuffer.resultBuffer.Dispose();
    }
    /// <summary>
    /// Set Basement buffers
    /// </summary>
    public static void SetBaseBuffer(ref PipelineBaseBuffer baseBuffer, ComputeShader compute, Vector4[] cullingPlanes)
    {
        compute.SetVectorArray(ShaderIDs.planes, cullingPlanes);
        compute.SetBuffer(0, ShaderIDs.clusterBuffer, baseBuffer.clusterBuffer);
        compute.SetBuffer(0, ShaderIDs.instanceCountBuffer, baseBuffer.instanceCountBuffer);
        compute.SetBuffer(1, ShaderIDs.instanceCountBuffer, baseBuffer.instanceCountBuffer);
        compute.SetBuffer(0, ShaderIDs.resultBuffer, baseBuffer.resultBuffer);
    }

    public static void SetShaderBuffer(ref PipelineBaseBuffer basebuffer)
    {
        basebuffer.geometryCommand.Clear();
        basebuffer.geometryCommand.SetRenderTarget(gBufferIdentifier, BuiltinRenderTextureType.CameraTarget);
        Shader.SetGlobalBuffer(ShaderIDs.verticesBuffer, basebuffer.verticesBuffer);
        Shader.SetGlobalBuffer(ShaderIDs.resultBuffer, basebuffer.resultBuffer);
    }
    public static void RunCullDispatching(ref PipelineBaseBuffer baseBuffer, ComputeShader computeShader)
    {
        computeShader.Dispatch(1, 1, 1, 1);
        ComputeShaderUtility.Dispatch(computeShader, 0, baseBuffer.clusterCount, 64);
    }
    public static void RenderProceduralCommand(ref PipelineBaseBuffer buffer, Material material)
    {
        buffer.geometryCommand.DrawProceduralIndirect(Matrix4x4.identity, material, 0, MeshTopology.Triangles, buffer.instanceCountBuffer);
    }
    public static void RenderShadowProcedural(ref ShadowMapComponent shadMap, ref PipelineBaseBuffer baseBuffer, int pass)
    {
        shadMap.shadowDepthMaterial.SetPass(pass);
        Graphics.DrawProceduralIndirect(MeshTopology.Triangles, baseBuffer.instanceCountBuffer);
    }
}