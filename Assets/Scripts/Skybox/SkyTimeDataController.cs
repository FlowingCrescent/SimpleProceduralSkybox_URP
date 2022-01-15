using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SkyTimeDataController : MonoBehaviour
{
    [System.Serializable]
    public class SkyTimeDataCollection
    {
        public SkyTimeData time0;
        public SkyTimeData time3;
        public SkyTimeData time6;
        public SkyTimeData time9;
        public SkyTimeData time12;
        public SkyTimeData time15;
        public SkyTimeData time18;
        public SkyTimeData time21;
    }
    private SkyTimeData newData = ScriptableObject.CreateInstance("SkyTimeData") as SkyTimeData;
    public SkyTimeDataCollection skyTimeDataCollection = new SkyTimeDataCollection();

    private void OnEnable() {
        newData = ScriptableObject.CreateInstance("SkyTimeData") as SkyTimeData;
    }

    public SkyTimeData GetSkyTimeData(float time)
    {
        SkyTimeData start = skyTimeDataCollection.time0;
        SkyTimeData end = skyTimeDataCollection.time0;

        if(time >= 0 && time < 3)
        {
            start = skyTimeDataCollection.time0;
            end = skyTimeDataCollection.time3;
        }
        else if(time >= 3 && time < 6)
        {
            start = skyTimeDataCollection.time3;
            end = skyTimeDataCollection.time6;
        }
        else if(time >= 6 && time < 9)
        {
            start = skyTimeDataCollection.time6;
            end = skyTimeDataCollection.time9;
        }
        else if(time >= 9 && time < 12)
        {
            start = skyTimeDataCollection.time9;
            end = skyTimeDataCollection.time12;
        }
        else if(time >= 12 && time < 15)
        {
            start = skyTimeDataCollection.time12;
            end = skyTimeDataCollection.time15;
        }
        else if(time >= 15 && time < 18)
        {
            start = skyTimeDataCollection.time15;
            end = skyTimeDataCollection.time18;
        }
        else if(time >= 18 && time < 21)
        {
            start = skyTimeDataCollection.time18;
            end = skyTimeDataCollection.time21;
        }
        else if(time >= 21 && time < 24)
        {
            start = skyTimeDataCollection.time21;
            end = skyTimeDataCollection.time0;
        }

        float lerpValue = (time % 3 / 3f);
        newData.skyColorGradientTex = GenerateSkyGradientColorTex(start.skyColorGradient, end.skyColorGradient, 128, lerpValue);

        newData.starIntensity = Mathf.Lerp(start.starIntensity, end.starIntensity, lerpValue);
        newData.milkywayIntensity = Mathf.Lerp(start.milkywayIntensity, end.milkywayIntensity, lerpValue);
        newData.sunIntensity = Mathf.Lerp(start.sunIntensity, end.sunIntensity, lerpValue);
        newData.scatteringIntensity = Mathf.Lerp(start.scatteringIntensity, end.scatteringIntensity, lerpValue);




        return newData;
    }



    public Texture2D GenerateSkyGradientColorTex(Gradient startGradient, Gradient endGradient, int resolution, float lerpValue)
    {
        Texture2D tex = new Texture2D(resolution, 1, TextureFormat.RGBAFloat, false, true);
        tex.filterMode = FilterMode.Bilinear;
        tex.wrapMode = TextureWrapMode.Clamp;
        

        for(int i = 0; i < resolution; i++)
        {
            Color start = startGradient.Evaluate(i * 1.0f / resolution).linear;
            Color end = endGradient.Evaluate(i * 1.0f / resolution).linear;

            Color fin = Color.Lerp(start, end, lerpValue);

            tex.SetPixel(i, 0, fin);
        }
        tex.Apply(false, false);
        
        return tex;
    }


}
