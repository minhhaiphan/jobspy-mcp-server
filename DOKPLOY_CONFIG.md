# Dokploy Configuration Guide

## Critical Configuration Settings

When deploying on Dokploy, use these **exact** settings:

### Build Configuration

1. **Build Type:** `Dockerfile`
2. **Dockerfile Path:** `Dockerfile` (or `./Dockerfile`)
3. **Build Context:** `.` (IMPORTANT: Must be root directory)
4. **Docker Build Args:** (leave empty unless needed)

### Why the Build Context Matters

The error you're seeing:
```
ERROR: failed to calculate checksum of ref: "/package.json": not found
```

This happens when the **Build Context** is not set to `.` (the root directory).

## Step-by-Step Fix in Dokploy

1. **Go to your Application in Dokploy Dashboard**

2. **Navigate to Build Settings**

3. **Check/Update these fields:**
   ```
   Repository: your-github-repo
   Branch: main
   Build Type: Dockerfile
   Dockerfile Path: Dockerfile
   Build Context: .
   ```

4. **Verify the Build Context field specifically:**
   - It should be exactly: `.`
   - NOT: `/` or empty or `./src` or anything else
   - The `.` means "use the root of the repository"

5. **Save and Redeploy**

## Alternative: Use Different Dockerfile Pattern

If Dokploy still has issues, you can also try using `npm install` instead of `npm ci`:

Change line 12 in Dockerfile from:
```dockerfile
RUN npm ci --omit=dev
```

To:
```dockerfile
RUN npm install --production
```

However, `npm ci` is preferred for production as it's faster and more reliable.

## Testing Locally

Before deploying, you can test the Docker build locally:

```bash
# Build the image
docker build -t jobspy-mcp-test .

# Run it
docker run -p 9423:9423 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jobspy-mcp-test
```

If this works locally but fails on Dokploy, it confirms the issue is with Dokploy's build context configuration.

## Common Dokploy Issues

### Issue 1: Build Context Not Set
**Symptom:** `"/package.json": not found`
**Solution:** Set Build Context to `.`

### Issue 2: Wrong Dockerfile Path
**Symptom:** `failed to solve with frontend dockerfile.v0`
**Solution:** Set Dockerfile Path to `Dockerfile` (not `./jobspy/Dockerfile`)

### Issue 3: Subpath Deployment
**Symptom:** Files not found even with correct settings
**Solution:** Make sure you're deploying from the repository root, not a subdirectory

## Dokploy UI Screenshots Checklist

When configuring in Dokploy, verify you see:
- [ ] Build Type dropdown shows "Dockerfile" selected
- [ ] Dockerfile Path field contains: `Dockerfile`
- [ ] Build Context field contains: `.`
- [ ] Repository is correctly connected
- [ ] Branch is correct (usually `main` or `master`)

## If Still Not Working

Try this temporary workaround - change the Dockerfile to use a wildcard that will work:

```dockerfile
# Copy everything first, then install
COPY . .
RUN npm ci --omit=dev
```

But this is less efficient. The proper fix is ensuring Dokploy's build context is set correctly.
