using UnityEngine;
using System.Collections;

public class Rotate : MonoBehaviour
{

	public Vector3 rotateAxis = new Vector3 (1f, 1f, 1f);
	
	// Update is called once per frame
	void Update ()
	{
		transform.Rotate (rotateAxis, rotateAxis.magnitude * Time.deltaTime);
	}
}
