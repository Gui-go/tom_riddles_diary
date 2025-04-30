FROM ollama/ollama:latest

EXPOSE 11434

RUN nohup bash -c "ollama serve &" && \
    sleep 5 && \
    ollama pull phi3

# CMD ["/bin/ollama", "serve"]
# ENTRYPOINT ["/usr/lib/ollama/ollama"]
# CMD ["serve"]