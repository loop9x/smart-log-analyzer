
```sh
OTEL_AGENT_JAR="$PWD/trip-booking/log-generator/opentelemetry-javaagent.jar"
export JAVA_TOOL_OPTIONS='-javaagent:$OTEL_AGENT_JAR'

camel run car-booking.camel.yaml application-dev.properties
camel run flight-booking.camel.yaml application-dev.properties
camel run hotel-booking.camel.yaml application-dev.properties
camel run trip-booking.camel.yaml application-dev.properties
```