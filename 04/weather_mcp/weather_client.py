import asyncio
from fastmcp import Client

client = Client("weather_server.py")

async def call_tool(name: str):
    async with client:
        result = await client.call_tool("get_weather", {"city": name})
        print(result)

asyncio.run(call_tool("berlin"))