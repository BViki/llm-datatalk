from fastmcp import FastMCP

mcp = FastMCP("Weather MCP Server")

known_weather_data = {'berlin': 20.0,
 'los angeles': 30,
 'san francisco': 49,
 'seattle': 34,
 'san diego': 43,
 'portland': 54,
 'new york city': 60,
 'boston': 57,
 'washington, d.c.': 36,
 'philadelphia': 82,
 'miami': 49
 }

@mcp.tool
def get_weather(city: str) -> float:
    """
    Retrieves the temperature for a specified city.

    Parameters:
        city (str): The name of the city for which to retrieve weather data.

    Returns:
        float: The temperature associated with the city.
    """
    city = city.strip().lower()

    if city in known_weather_data:
        return known_weather_data[city]

    return round(random.uniform(-5, 35), 1)

@mcp.tool
def set_weather(city: str, temp: float) -> None:
    """
    Sets the temperature for a specified city.

    Parameters:
        city (str): The name of the city for which to set the weather data.
        temp (float): The temperature to associate with the city.

    Returns:
        str: A confirmation string 'OK' indicating successful update.
    """
    city = city.strip().lower()
    known_weather_data[city] = temp
    return 'OK'

if __name__ == "__main__":
    mcp.run()






