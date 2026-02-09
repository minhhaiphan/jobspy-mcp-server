# Deploying JobSpy MCP Server on Dokploy

This guide walks you through deploying the JobSpy MCP Server on Dokploy using GitHub and Dockerfile.

## Prerequisites

- A Dokploy instance running (self-hosted or cloud)
- Your GitHub repository connected to Dokploy
- Docker daemon running on the Dokploy host

## Architecture Overview

This application consists of two components:
1. **Node.js MCP Server** - The main application (port 9423)
2. **JobSpy Python Service** - Job scraping tool (runs as Docker container)

The Node.js server spawns the JobSpy container on-demand for each job search request.

## Step-by-Step Deployment

### 1. Prepare Your Repository

Ensure you have pushed all changes to your GitHub repository:
```bash
git add .
git commit -m "Add production Dockerfile for Dokploy deployment"
git push origin main
```

### 2. Build the JobSpy Image on Dokploy Host

Since the MCP server calls `docker run jobspy`, you need to build the JobSpy image on your Dokploy host first.

**Option A: SSH into Dokploy host and build manually**
```bash
# SSH into your Dokploy host
ssh your-dokploy-host

# Clone the repo (or pull latest)
cd /path/to/clone
git clone https://github.com/YOUR_USERNAME/jobspy-mcp-server.git
cd jobspy-mcp-server

# Build the JobSpy image
docker build -t jobspy ./jobspy

# Verify the image
docker images | grep jobspy
```

**Option B: Use Dokploy's pre-build hook**

In Dokploy, you can configure a pre-build command to build the JobSpy image before deploying the MCP server.

### 3. Create Application in Dokploy

1. **Login to Dokploy Dashboard**
2. **Create New Application**
   - Name: `jobspy-mcp-server`
   - Provider: **GitHub**
   - Repository: Select your repository
   - Branch: `main` (or your preferred branch)

### 4. Configure Build Settings

In the Application settings:

**Build Configuration:**
- **Build Type:** Dockerfile
- **Dockerfile Path:** `./Dockerfile` (the root Dockerfile, not `jobspy/Dockerfile`)
- **Build Context:** `.` (root directory)

**Advanced Build Options (Optional):**
If you chose Option B above, add a pre-build command:
```bash
docker build -t jobspy ./jobspy
```

### 5. Configure Environment Variables

In Dokploy, add the following environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `JOBSPY_HOST` | `0.0.0.0` | Server host binding |
| `JOBSPY_PORT` | `9423` | Server port |
| `ENABLE_SSE` | `1` | Enable Server-Sent Events |
| `JOBSPY_DOCKER_IMAGE` | `jobspy` | JobSpy Docker image name |

### 6. Configure Port Mapping

- **Container Port:** `9423`
- **Host Port:** `9423` (or your preferred external port)
- **Protocol:** TCP

### 7. Configure Volume Mounts (CRITICAL)

This is the most important step. The container needs access to Docker to spawn JobSpy containers.

**Add Volume Mount:**
- **Host Path:** `/var/run/docker.sock`
- **Container Path:** `/var/run/docker.sock`
- **Read/Write:** Read-Write

This allows the container to communicate with the host's Docker daemon.

### 8. Deploy

Click **Deploy** to start the deployment process.

Dokploy will:
1. Pull your code from GitHub
2. Run the pre-build command (if configured)
3. Build the Docker image using your Dockerfile
4. Start the container with the specified configuration

### 9. Verify Deployment

**Check health endpoint:**
```bash
curl http://your-dokploy-host:9423/health
```

Expected response:
```json
{"status":"ok"}
```

**Check logs in Dokploy:**
Look for these log messages:
```
[INFO] Starting JobSpy MCP server...
[INFO] SSE server listening at http://0.0.0.0:9423
[INFO] SSE transport listening at http://0.0.0.0:9423/sse
```

### 10. Test Job Search

```bash
curl -X POST http://your-dokploy-host:9423/api \
  -H "Content-Type: application/json" \
  -d '{
    "searchTerm": "software engineer",
    "location": "San Francisco, CA",
    "siteNames": "indeed",
    "resultsWanted": 5
  }'
```

## Troubleshooting

### Issue: "docker: command not found"
**Solution:** The Dockerfile includes `docker-cli` installation. Make sure it's not being removed or modified.

### Issue: "Cannot connect to Docker daemon"
**Solution:** Verify that `/var/run/docker.sock` is properly mounted as a volume.

### Issue: "jobspy image not found"
**Solution:** Build the JobSpy image on the host:
```bash
docker build -t jobspy ./jobspy
```

### Issue: Port already in use
**Solution:** Change the `JOBSPY_PORT` environment variable or use a different host port mapping.

### Issue: Container fails to start
**Solution:** Check Dokploy logs for errors. Common issues:
- Missing environment variables
- Docker socket not mounted
- JobSpy image not built

## Updating the Deployment

To update your deployment:
1. Push changes to your GitHub repository
2. In Dokploy, click **Redeploy** on your application
3. Dokploy will pull the latest code and rebuild

## Optional: Custom Domain

In Dokploy, you can configure a custom domain:
1. Go to Application Settings → Domains
2. Add your domain (e.g., `jobspy.yourdomain.com`)
3. Dokploy will handle SSL/TLS certificates automatically

## Security Considerations

1. **Docker Socket Access:** Mounting `/var/run/docker.sock` gives the container access to the host's Docker daemon. This is necessary for functionality but should be used carefully in production.

2. **Network Isolation:** Consider using Docker networks to isolate the JobSpy containers.

3. **Resource Limits:** In Dokploy, set resource limits (CPU/Memory) to prevent resource exhaustion.

4. **Access Control:** Use Dokploy's authentication features or add an API gateway/reverse proxy with authentication.

## Performance Tuning

### Increase Timeout
If job searches are timing out, increase the timeout in your requests or set a higher default:
```bash
# Add environment variable
JOBSPY_TIMEOUT=120000  # 2 minutes in milliseconds
```

### Concurrent Searches
The server can handle multiple concurrent search requests. Monitor resource usage and adjust container limits accordingly.

## Support

For issues:
- Check Dokploy logs
- Review application logs
- Check that JobSpy container can be run manually: `docker run --rm jobspy --help`
