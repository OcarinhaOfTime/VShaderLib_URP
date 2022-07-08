using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointsSetter : MonoBehaviour {
    public Vector4[] points = new Vector4[3];
    void Update(){
        Shader.SetGlobalVectorArray("_Points", points);
        Shader.SetGlobalInt("_PointsSize", points.Length);
    }
}
