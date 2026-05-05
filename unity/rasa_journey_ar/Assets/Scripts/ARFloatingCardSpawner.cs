using System.Collections;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

public class ARFloatingCardSpawner : MonoBehaviour
{
    [SerializeField] private Camera arCamera;
    [SerializeField] private RestaurantInfoCardController infoCardPrefab;
    [SerializeField] private float spawnDistance = 1.2f;
    [SerializeField] private Vector3 localOffset = new(0f, -0.12f, 0f);

    private RestaurantInfoCardController _spawnedCard;

    private IEnumerator Start()
    {
        if (arCamera == null)
        {
            arCamera = Camera.main;
        }

        yield return WaitForTracking();
        SpawnCardInFrontOfCamera();
    }

    public void RespawnCard()
    {
        if (_spawnedCard != null)
        {
            Destroy(_spawnedCard.gameObject);
        }

        SpawnCardInFrontOfCamera();
    }

    private IEnumerator WaitForTracking()
    {
        while (ARSession.state != ARSessionState.SessionTracking)
        {
            yield return null;
        }
    }

    private void SpawnCardInFrontOfCamera()
    {
        if (arCamera == null || infoCardPrefab == null)
        {
            Debug.LogWarning("ARFloatingCardSpawner is missing the AR camera or card prefab.");
            return;
        }

        var worldPosition =
            arCamera.transform.position +
            (arCamera.transform.forward * spawnDistance) +
            arCamera.transform.TransformVector(localOffset);

        _spawnedCard = Instantiate(infoCardPrefab, worldPosition, Quaternion.identity);
        _spawnedCard.ApplyPayload(FlutterUnityBridge.ReadPayload());
    }
}
