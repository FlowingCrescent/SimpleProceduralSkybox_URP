using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SkyController : MonoBehaviour
{
    [Range(0f, 24f)]
    public float time = 9f;
    public bool timeGoes;
    public SkyTimeDataController skyTimeDataController;

    public Texture2D starTex;
    public Texture2D moonTex;
    public Light mainLight_Sun;
    public Light mainLight_Moon;
    public Transform sunTransform;
    public Transform moonTransform;
    public Transform milkyWayTransform;
    public Material skyboxMat;
    private float updateGITime = 0f;

    private const string _SkyGradientTex = "_SkyGradientTex";
    private const string _StarIntensity = "_StarIntensity";
    private const string _MilkywayIntensity = "_MilkywayIntensity";
    private const string _SunDirectionWS = "_SunDirectionWS";
    private const string _MoonDirectionWS = "_MoonDirectionWS";
    private const string _StarTex = "_StarTex";
    private const string _MoonTex = "_MoonTex";
    private const string _MoonWorld2Local = "_MoonWorld2Obj";
    private const string _MilkyWayWorld2Local = "_MilkyWayWorld2Local";
    private const string _ScatteringIntensity = "_ScatteringIntensity";
    private const string _SunIntensity = "_SunIntensity";


    private SkyTimeData currentSkyTimeData;
    private void OnEnable() 
    {
        skyTimeDataController = GetComponent<SkyTimeDataController>();
    }

    void Start()
    {
        
    }

    void Update()
    {

        if(timeGoes)
        {
            time += Time.deltaTime;
            updateGITime += Time.deltaTime;
        }
        
        time %= 24f;

        //Update GI
        if(updateGITime > 0.5f)
        {
            DynamicGI.UpdateEnvironment();
        }

        currentSkyTimeData = skyTimeDataController.GetSkyTimeData(time);

        ControllerSunAndMoonTransform();
        SetProperties();
    }


    public void ControllerSunAndMoonTransform()
    {
        mainLight_Sun.transform.eulerAngles = new Vector3((time - 6)*180/12, 180, 0);
        //mainLight_Sun.transform.eulerAngles = new Vector3((time - 6)*180/12, 180, 0);
        if(time >= 18)
            mainLight_Moon.transform.eulerAngles = new Vector3((time - 18)*180/12, 180, 0);
        else if(time >= 0)
            mainLight_Moon.transform.eulerAngles = new Vector3((time)*180/12 + 90, 180, 0);

        sunTransform.eulerAngles = mainLight_Sun.transform.eulerAngles;
        moonTransform.eulerAngles = mainLight_Moon.transform.eulerAngles;

        skyboxMat.SetVector(_SunDirectionWS, sunTransform.forward);
        skyboxMat.SetVector(_MoonDirectionWS, moonTransform.forward);
    }

    void SetProperties()
    {
        skyboxMat.SetTexture(_StarTex, starTex);
        skyboxMat.SetTexture(_MoonTex, moonTex);
        skyboxMat.SetTexture(_SkyGradientTex, currentSkyTimeData.skyColorGradientTex);
        skyboxMat.SetFloat(_StarIntensity, currentSkyTimeData.starIntensity);
        skyboxMat.SetFloat(_MilkywayIntensity, currentSkyTimeData.milkywayIntensity);
        skyboxMat.SetFloat(_ScatteringIntensity, currentSkyTimeData.scatteringIntensity);
        skyboxMat.SetFloat(_SunIntensity, currentSkyTimeData.sunIntensity);




        skyboxMat.SetMatrix(_MoonWorld2Local, moonTransform.worldToLocalMatrix);
        skyboxMat.SetMatrix(_MilkyWayWorld2Local, milkyWayTransform.worldToLocalMatrix);

    }
}
