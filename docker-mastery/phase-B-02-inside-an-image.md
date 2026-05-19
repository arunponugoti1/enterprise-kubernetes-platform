# 🎭 Phase B — Act 2: Crack Open the Blueprint (Inside a Real Image)

> **The "aha!" moment of Phase B.**
>
> By the end of this file, you will have torn apart your `account-service` image with your own hands, **seen every layer as a file on disk**, read the manifest JSON, and pointed at each sheet of the blueprint with your finger.

After this, "Docker image" will never feel mystical again.

---

## 🏗️ The Building Analogy (carried forward from your Q2)

In Phase B-01 you came up with the **architect's blueprint** model. We're going to use that the whole rest of Phase B:

| Docker thing | Building analogy |
|---|---|
| **Image** | Master blueprint folder for one building |
| **Manifest (JSON)** | The cover page of the folder: *"This building has 5 sheets, in this order, purpose: residential, height: 3 floors"* |
| **Layer** | One transparent sheet of the blueprint (foundation, plumbing, electrical, paint, signage) |
| **Layer hash (sha256)** | The serial-number stamp on each sheet |
| **Container** | A junior engineer constructing the building from the blueprint |
| **Container's writable layer** | The engineer's own scribble notepad placed on top while building |
| **`docker save`** | Photocopy the entire blueprint folder so you can take it home and study it |
| **`tar -xf`** | Open the folder and lay out every sheet individually on your desk |

**Key insight you'll discover today:** each "sheet" of the blueprint is **literally just a `.tar` file** containing the file changes from that step. Not magic. Files.

---

## 🎯 Today's mission

We will:

1. `docker save` your `account-service` image → get a single `.tar` file (the blueprint folder)
2. Extract it → see the **manifest** (cover page) + the **individual layer tarballs** (sheets)
3. Read the manifest JSON → see exactly what your image is made of
4. Pick one interesting layer → extract IT too → see the actual files inside
5. Run `docker history` → match the layers to the Dockerfile lines that created them

Your image: `enterprise-kubernetes-platform-account-service:latest` — 139 MB, 9 days old.

By the end you'll be able to answer:

- **What's actually inside a 139 MB image?**
- **How many layers does it have?**
- **Which layer is the heaviest, and why?** (This is the bug we'll fix in B5.)

---

## ⚙️ Environment setup

You need:
- **PowerShell** for `docker save` (you're on Windows)
- **Ubuntu WSL** for `tar`, `cat`, `jq` (these are awkward in PowerShell)
- A scratch folder to work in

### Step 0 — make a clean lab folder

In PowerShell:

```powershell
mkdir D:\docker-autopsy
cd D:\docker-autopsy
```

> 🏗️ **Building analogy:** *"You're cleaning a table on your desk so you can lay out the blueprint sheets one by one."*

---

## 🔪 Step 1 — `docker save` (photocopy the blueprint)

In **PowerShell**:

```powershell
docker save -o account-svc.tar enterprise-kubernetes-platform-account-service:latest
```

Wait ~15-30 seconds. Then check the file:

```powershell
ls account-svc.tar
```

You should see a file roughly **140-150 MB**.

> 🏗️ **What just happened:** You asked Docker to take the blueprint folder (your image, scattered across `/var/lib/docker/...` inside Docker Desktop's VM) and **bundle it all into ONE single `.tar` file** you can hold in your hand. This is exactly what happens behind the scenes when Docker pushes to a registry.

### 🧪 Sanity check — see the table of contents

You don't need to extract yet — `tar` can show you what's inside without unpacking. In **PowerShell** (Windows ships `tar.exe` by default):

```powershell
tar -tf account-svc.tar
```

You'll see something like:

```
blobs/sha256/12abc...
blobs/sha256/34def...
blobs/sha256/56ghi...
...
index.json
manifest.json
oci-layout
repositories
```

**Decoded:**
- `blobs/sha256/<hash>` → each one is a layer (a sheet of the blueprint) OR a config JSON. They're addressed by their **content hash** — change one byte, the hash changes completely.
- `manifest.json` → the **legacy** Docker manifest. The cover page in the old format.
- `index.json` → the **modern OCI** manifest. The new cover page format.
- `oci-layout` → a tiny file saying *"this is OCI format"*
- `repositories` → image-name-to-hash mapping

> 🏗️ **Already a revelation:** an "image" you've been pulling for months is literally a bunch of hash-named tarballs + a JSON file. That's it.

---

## 🔪 Step 2 — extract everything (lay out the sheets)

Switch to **Ubuntu WSL** for this (`tar` + `jq` are smoother there):

```bash
cd /mnt/d/docker-autopsy
mkdir extracted
tar -xf account-svc.tar -C extracted
cd extracted
ls -la
```

Expected output: a directory with `blobs/`, `index.json`, `manifest.json`, `oci-layout`, `repositories`.

```bash
ls -la blobs/sha256/ | head -20
```

You should see **8-15 files**, each named `<64-character-hash>`, with wildly different sizes (some 2 KB, some 100+ MB).

> 🏗️ **What you're looking at:** every transparent sheet of your blueprint, plus the cover pages. Each file is either a layer tarball OR a config JSON — same folder, told apart by inspecting them.

---

## 🔪 Step 3 — read the manifest (the cover page)

Install `jq` if you don't have it (one-time):

```bash
sudo apt install -y jq
```

Now read the modern manifest:

```bash
cat index.json | jq
```

You'll see something like:

```json
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:abc123...",
      "size": 1234
    }
  ]
}
```

That `digest` points to another blob — the **real manifest**. Follow the pointer:

```bash
# replace abc123... with your actual digest, only paste the part AFTER sha256:
cat blobs/sha256/25cfb1dbf2929972984afc5949c73dd806351268dae25289a65d0da809cc2ff3 | jq
```

Now you see the real blueprint cover page:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:xxxx...",
    "size": 2345
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:layer1...",
      "size": 30000000
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:layer2...",
      "size": 80000000
    },
    ...
  ]
}
```

**Read this slowly. This is the heart of B-02.**

- `config.digest` → points to another blob = the image's **runtime config** (env vars, CMD, working dir, exposed ports). Like the architect's "purpose of building + how the engineer should start work" note.
- `layers[]` → an ORDERED list of layer digests with their sizes. Each entry is one sheet.
- `size` → byte size of that sheet on disk

> 🏗️ **You are now holding the blueprint cover page in your hands.** Every Docker image on Earth has this exact structure. Nginx, Postgres, Kubernetes node images — all the same shape.

### ✍️ Note down for B-05

Count the layers and write down their sizes:

cat blobs/sha256/25cfb1dbf2929972984afc5949c73dd806351268dae25289a65d0da809cc2ff3 | jq
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:1ce9d101b548ec09b07473e299e640f4e4cc4a88ae823c09e56edcb69404f141",
    "size": 7965
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:29df493baa13de438d6d2ece3a8333032e0b7b9b9d8cce4ee82194da255f61e1",
      "size": 8732160
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:4983b93ee7967564f02cbf6162b75010ce557404a539fba05ee19a0eae01acbc",
      "size": 124029440
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:e10358715ead9b47009dd04bcd77ac1c8e247f7249ab06517ff913c473a8e38e",
      "size": 5389312
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:afa543f85b4685a84338df3e2c429edca49bb372b0f49e0c5cc9724c820ad094",
      "size": 3584
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:deb6b4d52db36853cce3b3085bac43c6e573b9b9b7adf15620cbedf7570ac8b8",
      "size": 1536
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:ade0f5d5cc0807f1b680c6f3126a9df2bafffc7345f42f71472ce42391c093a7",
      "size": 3755008
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:8a1f5d0db578c21d2c50244b4353ff7076b86fe7b23df64bd315a2816c77083e",
      "size": 2560
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar",
      "digest": "sha256:9df22a9771421f3a2df95f5e66a8de6c3d6320a79767a65e9f39fb591ad15320",
      "size": 7680
    }
  ]
}

```bash
cat blobs/sha256/25cfb1dbf2929972984afc5949c73dd806351268dae25289a65d0da809cc2ff3 | jq '.layers[] | {digest: .digest[7:19], size_mb: (.size / 1048576 | floor)}'
```

This will print something like:

```
{ "digest": "sha256:abc12...", "size_mb": 30 }
{ "digest": "sha256:def34...", "size_mb": 80 }
{ "digest": "sha256:ghi56...", "size_mb": 5 }
...
```

**Save this output.** In B-05 we'll target the fat layers and shrink them.
cat blobs/sha256/25cfb1dbf2929972984afc5949c73dd806351268dae25289a65d0da809cc2ff3 | jq '.layers[] | {digest: .digest[7:19], size_mb: (.size / 1048576 | floor)}'
{
  "digest": "29df493baa13",
  "size_mb": 8
}
{
  "digest": "4983b93ee796",
  "size_mb": 118
}
{
  "digest": "e10358715ead",
  "size_mb": 5
}
{
  "digest": "afa543f85b46",
  "size_mb": 0
}
{
  "digest": "deb6b4d52db3",
  "size_mb": 0
}
{
  "digest": "ade0f5d5cc08",
  "size_mb": 3
}
{
  "digest": "8a1f5d0db578",
  "size_mb": 0
}
{
  "digest": "9df22a977142",
  "size_mb": 0
}

---

## 🔪 Step 4 — peek inside the heaviest layer

Pick the LARGEST layer from Step 3 (probably 60-100 MB). Extract IT:

```bash
mkdir fat-layer
tar -xzf blobs/sha256/4983b93ee7967564f02cbf6162b75010ce557404a539fba05ee19a0eae01acbc -C fat-layer
ls -la fat-layer/
```

(use `-xzf` if it's gzipped, `-xf` if not — try both)

Now explore:

```bash
du -sh fat-layer/*
```

You'll see directories like `usr/`, `var/`, `etc/`, `app/` etc.

**The detective work:** sort by size and find what's hogging the layer.

```bash
du -ah fat-layer/ | sort -rh | head -20
```

Likely suspects in a Spring Boot / Java image:
- `usr/lib/jvm/` → the entire JDK (~200 MB)
- `root/.m2/` → leftover Maven cache (oops!)
- `app/target/*.jar` → your packaged app (~30-50 MB)
- `var/cache/apt/` → leftover apt cache (oops!)

> 🏗️ **What you're seeing:** the EXACT files that got added in this one step of the Dockerfile. Every `RUN apt install ...` leaves its packages here. Every `COPY` lands its files here. Now you understand why a careless Dockerfile bloats — you're staring at the bloat.

---

## 🔪 Step 5 — match layers to Dockerfile lines

Back in **PowerShell** (or WSL — `docker` works in both):

```powershell
docker history enterprise-kubernetes-platform-account-service:latest --no-trunc
```

You'll see a table:

```
IMAGE          CREATED        CREATED BY                                      SIZE
1ce9d101b548   9 days ago     CMD ["java" "-jar" "app.jar"]                   0B
<missing>      9 days ago     EXPOSE 8081                                     0B
<missing>      9 days ago     COPY target/*.jar /app/app.jar # buildkit       42MB
<missing>      9 days ago     WORKDIR /app                                    0B
<missing>      2 weeks ago    /bin/sh -c apt-get install -y openjdk-17-jdk    280MB
<missing>      2 weeks ago    /bin/sh -c apt-get update                       50MB
<missing>      3 weeks ago    /bin/sh -c #(nop) ADD file:abc...               80MB
```

**Read top to bottom in REVERSE order.** That's the Dockerfile execution order (the bottom is the base image, the top is the last instruction).

| `docker history` line | Sheet in your blueprint | What it added |
|---|---|---|
| `ADD file:abc... 80MB` | Sheet 1 (foundation) | Base Ubuntu/Debian rootfs |
| `apt-get update 50MB` | Sheet 2 | apt package metadata (oops — usually leftover) |
| `apt-get install openjdk-17 280MB` | Sheet 3 | The JDK (this is your fat layer) |
| `WORKDIR /app 0B` | (metadata only, no data) | Just a setting in the manifest |
| `COPY target/*.jar 42MB` | Sheet 4 | Your packaged Spring Boot jar |
| `EXPOSE 8081 0B` | (metadata only) | Just a setting |
| `CMD [...] 0B` | (metadata only) | The startup command |

### 💡 The huge realization

Lines with `0B` are **NOT new sheets**. They're just edits to the cover page (the manifest). Only `RUN`, `COPY`, `ADD` create new sheets.

This is your superpower for B-03 (layer cache) and B-04 (multi-stage builds):
- You now know exactly which lines cost megabytes
- You can predict which lines invalidate cache when changed
- You can see WHERE the fat is hiding

---

## 🧠 Connect back to runtime

Remember the Q2 lesson: when a container runs, the kernel uses **OverlayFS** to stack all these sheet-tarballs into one virtual filesystem, then adds a writable scribble-sheet on top.

So when your container does `cat /etc/os-release`:
1. OverlayFS looks at the top sheet — not there
2. Looks at sheet 2 — not there
3. Looks at sheet 1 (the base Ubuntu) — found! Returns the file.

When your container does `echo "hi" > /tmp/foo`:
1. The write goes ONLY to the writable scribble-sheet on top
2. The underlying sheets are untouched
3. When the container is deleted, the scribble-sheet is thrown away — image stays pristine

You can literally SEE where every file your container reads comes from by checking which layer it's in.

---

## ✍️ Your turn — self-check

Before B-03, answer these in writing:

1. **In your own words**, what is inside the `blobs/sha256/` folder, and how does Docker know which blob is a layer vs the manifest vs the config?

2. **Looking at your `docker history` output**, which layer is the heaviest in `account-service`, and what command created it? Paste the output.

3. **Prediction:** If you change ONE line of Java code in your account-service and rebuild, which layers from the `docker history` will be **re-built** vs **reused from cache**? Why? (Hint: think about the order of `COPY` vs `RUN apt install`.)

4. **Bonus:** Sum up the sizes of all your layers. Does it equal 139 MB? If not, why might there be a difference?

```
1. inside the it all the stuff related to docker images, it knows becasue index.json point to manifest, manifest point to config, layers

2. docker history enterprise-kubernetes-platform-account-service:latest, <missing>      4 weeks ago   RUN /bin/sh -c addgroup -g 1000 node     && …   122MB     buildkit.dockerfile.v0, 

3. COPY target/*.jar, layers after that,Reused from cache: base OS layer.apt install layer,JDK layer

4. yes 139

```

---

## 🎯 The mentor sentence to memorize

> *"A Docker image is a folder of hash-named tarballs plus a JSON manifest. Each tarball is a frozen filesystem-diff. `docker pull` is just downloading those tarballs. `docker run` is just stacking them with OverlayFS and adding a writable sheet on top. Nothing is hidden."*

If you can recite this, you've internalized the entire Docker image model. You are no longer afraid of `docker save`, `tar`, registry mirrors, or layer hashes.

---

## ➡️ Next file: `phase-B-03-the-layer-cache.md`

We weaponize what you just saw. We'll build the account-service image TWO ways:
- **Bad Dockerfile** → every code change triggers a 5-minute rebuild
- **Good Dockerfile** → every code change triggers a 5-second rebuild

Same end result. The difference is **the order of 4 lines**. You'll see it with a stopwatch.
