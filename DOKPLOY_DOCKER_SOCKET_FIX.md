# Fix Docker Socket Access in Dokploy

## ✅ Build Issue SOLVED!
Your application is now successfully deployed and running. However, there's a new issue to fix.

## ❌ Current Problem
The application can't access Docker to run JobSpy containers:
```
failed to connect to the docker API at unix:///var/run/docker.sock
```

## ✅ Solution: Mount Docker Socket

### In Dokploy Dashboard:

1. **Go to your Application Settings**

2. **Find the "Mounts" or "Volumes" section**

3. **Add a new volume mount:**
   ```
   Host Path:      /var/run/docker.sock
   Container Path: /var/run/docker.sock
   Type:           Bind Mount
   Read-Only:      No (needs write access)
   ```

4. **Save and restart the container**

### Alternative: Using Dokploy Configuration

If Dokploy uses docker-compose.yml or similar configuration, you need to add:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### Step-by-Step Visual Guide:

**Dokploy UI Steps:**
1. Click on your `jobspy-mcp-server` application
2. Navigate to **"Advanced"** or **"Mounts"** tab
3. Click **"Add Volume"** or **"Add Mount"**
4. Fill in:
   - Source/Host Path: `/var/run/docker.sock`
   - Target/Container Path: `/var/run/docker.sock`
   - Type: `bind` or `volume` (use bind)
5. Click **Save**
6. Click **Restart** or **Redeploy**

### Why This Is Needed

Your Node.js application needs to communicate with the Docker daemon on the host to:
1. Run the JobSpy container for each search request
2. Pass search parameters to JobSpy
3. Capture and process the results

Without the Docker socket mounted, the application can't create or run containers.

## Security Note

⚠️ **Important:** Mounting `/var/run/docker.sock` gives the container access to the Docker daemon. This is necessary for the application to work, but be aware that:

- The container can run any Docker commands
- Use only in trusted environments
- Consider network isolation for production

## Verification

After mounting the Docker socket and restarting:

1. **Check the logs** - The error should disappear

2. **Test a search request:**
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

3. **Look for success logs:**
   ```
   info: Starting job search with parameters
   info: Spawning process with args: docker run --rm jobspy...
   info: Job search completed successfully
   ```

## Pre-requisite: JobSpy Docker Image

Also make sure the `jobspy` Docker image is built on your Dokploy host:

```bash
# SSH into your Dokploy host
ssh your-dokploy-host

# Clone or pull your repo
git clone https://github.com/YOUR_USERNAME/jobspy-mcp-server.git
cd jobspy-mcp-server

# Build the JobSpy image
docker build -t jobspy ./jobspy

# Verify it's built
docker images | grep jobspy
```

This only needs to be done once. After that, your Node.js application can use it.

## If Docker Socket Still Doesn't Work

Some Dokploy instances may have restrictions. Alternative approaches:

### Option 1: Use Dokploy's Docker Network
Configure your application to use Docker's network mode to communicate with containers.

### Option 2: Pre-build JobSpy and Use Docker-in-Docker
Run a Docker-in-Docker sidecar container.

### Option 3: Kubernetes/Podman Alternative
If Dokploy uses Kubernetes, you may need a different approach using jobs or pods.

## Summary

**What's Fixed:**
- ✅ Docker build now works
- ✅ Application deploys successfully
- ✅ Server is running

**What Needs Fixing:**
- ❌ Docker socket not mounted → Mount `/var/run/docker.sock:/var/run/docker.sock`
- ❌ JobSpy image may not be built → Build with `docker build -t jobspy ./jobspy` on host

Once you mount the Docker socket, your application will work perfectly!
