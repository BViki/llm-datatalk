#!/bin/bash
# Load .env file from parent directory if it exists
ENV_FILE="/workspaces/llm-datatalk/.env"
if [ -f "$ENV_FILE" ]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
fi
export LLM_API_KEY=`echo $OPENAI_API_KEY`  
LOGDIR="$(pwd)/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/elastic_$(date +'%Y%m%d_%H%M%S').log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[$(date)] Script started."

start_services() {
  echo "[$(date)] Starting Elasticsearch Docker container..."
  docker run -d --rm \
    --name elasticsearch \
    -p 9200:9200 \
    -p 9300:9300 \
    -e "discovery.type=single-node" \
    -e "xpack.security.enabled=false" \
    elasticsearch:8.17.6

  # Wait for Elasticsearch to be ready
  echo "[$(date)] Waiting for Elasticsearch to be ready..."
  until curl -s http://localhost:9200 >/dev/null; do
    sleep 2
  done
  echo "[$(date)] Elasticsearch is up."

  # Check if Elasticsearch has any indexes
  INDEX_COUNT=$(curl -s http://localhost:9200/_cat/indices?h=index | wc -l)
  if [ "$INDEX_COUNT" -eq 0 ]; then
    echo "[$(date)] No indexes found. Loading Elasticsearch indexes via Jupyter notebook..."
    jupyter nbconvert --to notebook --execute /workspaces/llm-datatalk/01/Elastic_Indexes_Setup.ipynb \
      --output /workspaces/llm-datatalk/01/Elastic_Indexes_Setup_output.ipynb >> "$LOGFILE" 2>&1
    echo "[$(date)] Indexes loaded."
  else
    echo "[$(date)] Indexes already exist. Skipping index setup."
  fi

  echo "[$(date)] Starting Jupyter Notebook in background on port 8888..."
  nohup jupyter notebook --port=8888 --ip=0.0.0.0 --no-browser >> "$LOGFILE" 2>&1 &
  echo "[$(date)] Jupyter Notebook started in background on port 8888."
  echo "[$(date)] If using VS Code, use the 'Ports' panel to forward port 8888."

  echo "[$(date)] Pulling Qdrant Docker image..."
  docker pull qdrant/qdrant

  echo "[$(date)] Starting Qdrant Docker container..."
  docker run -d --rm \
    --name qdrant \
    -p 6333:6333 -p 6334:6334 \
    -v "$(pwd)/qdrant_storage:/qdrant/storage:z" \
    qdrant/qdrant
  echo "[$(date)] Qdrant started on ports 6333 and 6334."

  # echo "[$(date)] Loading Qdrant Collections via Jupyter notebook..."
  # jupyter nbconvert --to notebook --execute /workspaces/llm-datatalk/02/Load_Qdrant.ipynb \
  #     --output /workspaces/llm-datatalk/02/Load_Qdrant.ipynb >> "$LOGFILE" 2>&1
  # echo "[$(date)] Collections loaded."

  echo "[$(date)] All services started successfully."
}


stop_services() {
  echo "[$(date)] Stopping Jupyter Notebook..."
  pkill -f "jupyter-notebook"

  # echo "[$(date)] Stopping Elasticsearch Docker container..."
  # docker stop elasticsearch

  echo "[$(date)] Stopping Qdrant Docker container..."
  docker stop qdrant
}

case "$1" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    ;;
esac

echo "[$(date)] Script finished."