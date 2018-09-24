﻿using System.Collections;
using System.Collections.Generic;
using Unity.Collections;

using UnityEngine;
[RequireComponent(typeof(Light))]
[RequireComponent(typeof(Camera))]
public class SunLight : MonoBehaviour
{
    public static SunLight current = null;
    public ShadowmapSettings settings;
    public static ShadowMapComponent shadMap;
    private void Awake()
    {
        var light = GetComponent<Light>();
        if (current)
        {
            Debug.Log("Sun Light Should be Singleton!");
            Destroy(light);
            Destroy(this);
            return;
        }
        current = this;
        shadMap.light = light;
        light.enabled = false;
        shadMap.shadowmapTexture = new RenderTexture(settings.resolution, settings.resolution, 16, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        shadMap.shadowmapTexture.filterMode = FilterMode.Point;
        shadMap.frustumCorners = new NativeArray<Vector3>(8, Allocator.Persistent, NativeArrayOptions.UninitializedMemory);
        shadMap.shadowCam = GetComponent<Camera>();
        shadMap.shadowCam.enabled = false;
        shadMap.shadowCam.orthographic = true;
        shadMap.shadowCam.renderingPath = RenderingPath.Forward;
        shadMap.shadowCam.useOcclusionCulling = true;
        shadMap.shadowCam.allowMSAA = false;
        shadMap.shadowCam.allowHDR = false;
        shadMap.shadowCam.targetTexture = shadMap.shadowmapTexture;
        shadMap.shadowDepthMaterial = new Material(Shader.Find("Hidden/ShadowDepth"));
        shadMap.shadowFrustumPlanes = new NativeArray<AspectInfo>(3, Allocator.Persistent, NativeArrayOptions.UninitializedMemory);
        Vector3 eulerAngle = transform.eulerAngles;
        eulerAngle.z = Random.Range(5f, 355f);
        transform.eulerAngles = eulerAngle;
    }

    private void OnDestroy()
    {
        if (current != this) return;
        current = null;
        shadMap.frustumCorners.Dispose();
        shadMap.shadowmapTexture.Release();
        Destroy(shadMap.shadowmapTexture);
        Destroy(shadMap.shadowDepthMaterial);
        shadMap.shadowFrustumPlanes.Dispose();
    }
}
