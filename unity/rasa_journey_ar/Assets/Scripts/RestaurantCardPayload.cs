using System;

[Serializable]
public class RestaurantCardPayload
{
    public string restaurantName = "RasaJourney Food Spot";
    public string cuisineLabel = "Perlis Food Pick";
    public string status = "Open now";
    public string hours = "10:00 AM - 10:00 PM";
    public string rating = "4.6 / 5";
    public string subtitle = "Point your camera to preview a floating restaurant info card.";

    public static RestaurantCardPayload Demo()
    {
        return new RestaurantCardPayload();
    }
}
