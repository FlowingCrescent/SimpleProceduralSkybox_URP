using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName ="Skybox/SkyTimeData")]
public class SkyTimeData : ScriptableObject
{
    public Gradient skyColorGradient;
    public float sunIntensity;
    public float scatteringIntensity;
    public float starIntensity;
    public float milkywayIntensity;



    [HideInInspector]
    public Texture2D skyColorGradientTex;
}
