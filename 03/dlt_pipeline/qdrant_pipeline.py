import dlt
import requests
from dlt.destinations import qdrant

print("dlt version:", dlt.__version__)

qdrant_destination = qdrant(
    url="http://localhost:6333",  # Replace with your Qdrant URL
    api_key=None,  # Replace with your Qdrant API key if needed
)

@dlt.resource(write_disposition="replace")
def zoomcamp_data():
    docs_url = 'https://github.com/alexeygrigorev/llm-rag-workshop/raw/main/notebooks/documents.json'
    docs_response = requests.get(docs_url)
    documents_raw = docs_response.json()

    for course in documents_raw:
        course_name = course['course']

        for doc in course['documents']:
            doc['course'] = course_name
            yield doc


pipeline = dlt.pipeline(
    pipeline_name="zoomcamp_pipeline", 
    destination=qdrant_destination,
    dataset_name="zoomcamp_tagged_data"

)
load_info = pipeline.run(zoomcamp_data())
print(pipeline.last_trace)