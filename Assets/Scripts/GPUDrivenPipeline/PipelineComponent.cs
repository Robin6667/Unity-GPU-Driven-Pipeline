using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

public struct PipelineBaseBuffer
{
    public ComputeBuffer clusterBuffer;    //ObjectInfo
    public ComputeBuffer instanceCountBuffer; //uint4
    public ComputeBuffer resultBuffer; //uint
    public ComputeBuffer verticesBuffer;    //Point
    public CommandBuffer geometryCommand;
    public int clusterCount;
    public int clusterOffset;
    public const int UINTSIZE = 4;
    public const int INDIRECTSIZE = 16;
    public const int CLUSTERCLIPCOUNT = 64;
    public const int CLUSTERVERTEXCOUNT = CLUSTERCLIPCOUNT * 6 / 4;
}

public struct ShadowMaskComponent
{
    public Material shadowmaskMaterial;
    public CommandBuffer afterLightingBuffer;
}

public struct AspectInfo
{
    public Vector3 inPlanePoint;
    public Vector3 planeNormal;
    public float size;
}
[System.Serializable]
public struct ShadowmapSettings
{
    public int resolution;
    public float firstLevelDistance;
    public float secondLevelDistance;
    public float thirdLevelDistance;
    public float farestDistance;
    public Vector4 bias;
    public Vector4 normalBias;
    public Vector4 cascadeSoftValue;
}

public struct ShadowMapComponent
{
    public Camera shadowCam;
    public Material shadowDepthMaterial;
    public RenderTexture shadowmapTexture;
    public NativeArray<Vector3> frustumCorners;
    public NativeArray<AspectInfo> shadowFrustumPlanes;
    public Light light;
}
[System.Serializable]
public struct Point
{
    public Vector3 vertex;
    public Vector4 tangent;
    public Vector3 normal;
    public Vector2 texcoord;
    public const int SIZE = 48;
}
[System.Serializable]
public struct ObjectInfo
{
    public Vector3 extent;
    public Vector3 position;
    public const int SIZE = 24;
}
public struct PerObjectData
{
    public Vector3 extent;
    public uint instanceOffset;
    public const int SIZE = 16;
}

public struct StaticFit
{
    public int resolution;
    public Camera shadowCam;
    public Camera mainCamTrans;
    public NativeArray<Vector3> frustumCorners;
}