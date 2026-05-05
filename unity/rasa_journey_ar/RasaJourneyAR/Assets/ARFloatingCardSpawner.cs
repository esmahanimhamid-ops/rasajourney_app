using UnityEngine;

public class ARFloatingCardSpawner : MonoBehaviour
{
    public Camera mainCamera;
    public GameObject restaurantInfoCardPrefab;

    private GameObject spawnedCard;

    void Start()
    {
        SpawnCard();
    }

    void SpawnCard()
    {
        if (mainCamera == null || restaurantInfoCardPrefab == null) return;

        Vector3 spawnPosition = mainCamera.transform.position + mainCamera.transform.forward * 1.2f;

        spawnedCard = Instantiate(restaurantInfoCardPrefab, spawnPosition, Quaternion.identity);
    }
}