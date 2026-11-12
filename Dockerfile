FROM metabase/metabase:v0.65.3

# Render's free Web Service exposes port 10000 and has 512 MB RAM.
ENV MB_JETTY_HOST=0.0.0.0 \
    MB_JETTY_PORT=10000 \
    JAVA_TIMEZONE=America/Sao_Paulo \
    JAVA_TOOL_OPTIONS="-Xms48m -Xmx160m -XX:MaxMetaspaceSize=192m -XX:ReservedCodeCacheSize=32m -XX:MaxDirectMemorySize=32m -XX:ActiveProcessorCount=1 -Xss256k"
