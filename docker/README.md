# Servidor web en contenedor

```bash
docker build -t nginx-vm3 .                       # nginx-vm4 en VM4
docker run -d --name nginx-web -p 80:80 --restart always nginx-vm3
docker ps                                         # comprobar
sudo reboot && docker ps                          # vuelve a arrancar solo
```

`index.html` es un panel que centraliza el acceso a Prometheus, Grafana y las estadísticas de HAProxy.
