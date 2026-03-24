#!/bin/bash

SESSION="smart-log-demo"
WAIT_TIME=10
OTEL_AGENT_JAR="$PWD/trip-booking/log-generator/opentelemetry-javaagent.jar"
OTEL_ENV="export JAVA_TOOL_OPTIONS='-javaagent:$OTEL_AGENT_JAR' && export OTEL_TRACES_EXPORTER=otlp && export OTEL_LOGS_EXPORTER=otlp && export OTEL_METRICS_EXPORTER=none"

export OPENAI_API_KEY=your-api-key
export OPENAI_BASE_URL=http://localhost:11434/v1  # Ollama example
export OPENAI_MODEL=granite-4-0-h-tiny

# 1. Cleanup old session if it exists to start fresh
tmux kill-session -t $SESSION 2>/dev/null

# 2. Start the session with the first window named "Analyzer"
# 'env -u TMUX' helps bypass the nesting error
env -u TMUX tmux new-session -d -s $SESSION -n "Analyzer"
tmux set-option -t $SESSION mouse on

# --- WINDOW: Analyzer ---
# Infrastructure
tmux send-keys -t "$SESSION:Analyzer" "cd containers && docker-compose up" C-m

# Correlator (Vertical split)
tmux split-window -h -t "$SESSION:Analyzer"
tmux send-keys -t "$SESSION:Analyzer" "echo 'Waiting...' && sleep ${WAIT_TIME} && cd correlator && camel run traces-mapper.camel.yaml logs-mapper.camel.yaml infinispan.camel.yaml kaoto-datamapper-4a94acc3.xsl kaoto-datamapper-8f5bb2dd.xsl" C-m

# Analyzer (Horizontal split)
tmux split-window -v -t "$SESSION:Analyzer"
tmux send-keys -t "$SESSION:Analyzer" "echo 'Waiting...' && sleep ${WAIT_TIME} && cd analyzer && camel run error-analyzer.camel.yaml status-api.camel.yaml" C-m

# UI Console
tmux split-window -v -t "$SESSION:Analyzer"
tmux send-keys -t "$SESSION:Analyzer" "cd ui-console && camel run *" C-m
tmux select-layout -t "$SESSION:Analyzer" tiled

# --- WINDOW: App-Services ---
tmux new-window -t $SESSION -n "App-Services"

# Car Booking
tmux send-keys -t "$SESSION:App-Services" "echo 'Waiting...' && sleep ${WAIT_TIME} && cd trip-booking/car-booking && $OTEL_ENV && export OTEL_SERVICE_NAME=car-booking && camel run car-booking.camel.yaml application-dev.properties" C-m

# Flight Booking (Split)
tmux split-window -v -t "$SESSION:App-Services"
tmux send-keys -t "$SESSION:App-Services" "echo 'Waiting...' && sleep ${WAIT_TIME} && cd trip-booking/flight-booking && $OTEL_ENV && export OTEL_SERVICE_NAME=flight-booking && camel run flight-booking.camel.yaml application-dev.properties" C-m

# Hotel Booking (Split)
tmux split-window -v -t "$SESSION:App-Services"
tmux send-keys -t "$SESSION:App-Services" "echo 'Waiting...' && sleep ${WAIT_TIME} && cd trip-booking/hotel-booking && $OTEL_ENV && export OTEL_SERVICE_NAME=hotel-booking && camel run hotel-booking.camel.yaml application-dev.properties" C-m

# Trip Booking (Split)
tmux split-window -v -t "$SESSION:App-Services"
tmux send-keys -t "$SESSION:App-Services" "echo 'Waiting 20s...' && sleep 20 && cd trip-booking && $OTEL_ENV && export OTEL_SERVICE_NAME=trip-booking && camel run trip-booking.camel.yaml application-dev.properties" C-m

tmux select-layout -t "$SESSION:App-Services" tiled

# 3. Finalize
tmux select-window -t "$SESSION:Analyzer"
env -u TMUX tmux attach-session -t $SESSION

