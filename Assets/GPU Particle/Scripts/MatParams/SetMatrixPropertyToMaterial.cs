using UnityEngine;
using System.Collections;

public class SetMatrixPropertyToMaterial : MonoBehaviour
{
	public string prefix = "_Cam";

	[SerializeField]
	string
		propModelToWorld = "_O2W",
		propWorldToModel = "_W2O",
		propWorldToCam = "_W2C",
		propCamToWorld = "_C2W",
		propCamProjection = "_C2P",
		propCamVP = "_VP",
		propScreenToCam = "_S2C",
		propProjectionParams = "_PParams",
		propScreenParams = "_SParams";

	public Material targetMat;

	Camera cam;

	// Use this for initialization
	void Awake ()
	{
		cam = GetComponent<Camera> ();
		SetParams ();
	}
	
	// Update is called once per frame
	void Update ()
	{
		if (transform.hasChanged)
			SetParams ();
		transform.hasChanged = false;
	}

	void SetParams ()
	{
		var modelToWorld = transform.localToWorldMatrix;
		var worldToModel = transform.worldToLocalMatrix;

		if (targetMat != null) {
			targetMat.SetMatrix (prefix + propModelToWorld, modelToWorld);
			targetMat.SetMatrix (prefix + propWorldToModel, worldToModel);
		} else {
			Shader.SetGlobalMatrix (prefix + propModelToWorld, modelToWorld);
			Shader.SetGlobalMatrix (prefix + propWorldToModel, worldToModel);
		}

		if (cam != null) {
			SetCamParams ();
		}
	}

	void SetCamParams ()
	{
		var worldToCam = cam.worldToCameraMatrix;
		var camToWorld = cam.cameraToWorldMatrix;
		var projection = GL.GetGPUProjectionMatrix (cam.projectionMatrix, false);
		var inverseP = projection.inverse;
		var vp = projection * worldToCam;
		var projectionParams = new Vector4 (1f, cam.nearClipPlane, cam.farClipPlane, 1f / cam.farClipPlane);
		var screenParams = new Vector4 (cam.pixelWidth, cam.pixelHeight, 1f + 1f / (float)cam.pixelWidth, 1f + 1f / (float)cam.pixelHeight);

		if (targetMat != null) {
			targetMat.SetMatrix (prefix + propWorldToCam, worldToCam);
			targetMat.SetMatrix (prefix + propCamProjection, projection);
			targetMat.SetMatrix (prefix + propCamVP, vp);
			targetMat.SetMatrix (prefix + propScreenToCam, inverseP);
			targetMat.SetMatrix (prefix + propCamToWorld, camToWorld);
			targetMat.SetVector (prefix + propProjectionParams, projectionParams);
			targetMat.SetVector (prefix + propScreenParams, screenParams);
		} else {
			Shader.SetGlobalMatrix (prefix + propWorldToCam, worldToCam);
			Shader.SetGlobalMatrix (prefix + propCamProjection, projection);
			Shader.SetGlobalMatrix (prefix + propCamVP, vp);
			Shader.SetGlobalMatrix (prefix + propScreenToCam, inverseP);
			Shader.SetGlobalMatrix (prefix + propCamToWorld, camToWorld);
			Shader.SetGlobalVector (prefix + propProjectionParams, projectionParams);
			Shader.SetGlobalVector (prefix + propScreenParams, screenParams);
		}
	}
}
