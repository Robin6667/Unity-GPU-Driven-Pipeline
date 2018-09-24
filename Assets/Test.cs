using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour {
    public Mesh mesh;
    public Material mat;
    public Transform trans;
	// Use this for initialization
	void Start () {
		
	}
    private void OnPostRender()
    {
        mat.SetPass(0);
        Graphics.DrawMeshNow(mesh, trans.localToWorldMatrix);
    }
}
