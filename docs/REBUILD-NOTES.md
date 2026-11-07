# Rebuilding a Ludus template from `ludus-source-bsl`

Procedure used to rebuild `win2025-server-x64-tpm-template` fresh when it
was misbehaving on this Ludus server (see `docs/VMS.md` for why). Keeping
this as a reusable runbook — the same gotchas apply to any stock template.

## 1. Clear anything using the template first

`deleteTemplate` fails with `409: base volume '...' is still in use by
linked cloned` if any VM anywhere is still a linked clone of it. There's no
per-VM delete in the Ludus API — only `deleteRangeVMs`, which wipes an
entire range. If the template is only used by one range, wipe that range's
VMs first:

```
mcp__ludus__call_ludus_api deleteRangeVMs, path_params {"rangeID": "<id>"}, confirm: true
```

## 2. Delete the template — but know what this actually does

```
mcp__ludus__call_ludus_api deleteTemplate, path_params {"name": "<template-name>"}, confirm: true
```

**This removes the entire template *definition* from Ludus's catalog, not
just the built VM image.** After this, `getTemplates` no longer lists the
template at all — it has to be re-registered from source, not just rebuilt.

## 3. Get the exact source files — git clone, not WebFetch

Templates live under `templates/<name>/` in
[`badsectorlabs/ludus-source-bsl`](https://github.com/badsectorlabs/ludus-source-bsl).
Use a shallow sparse-checkout to get byte-exact files (an `Autounattend.xml`
or `.pkr.hcl` reconstructed from a WebFetch summary could easily be subtly
wrong and silently break the build):

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/badsectorlabs/ludus-source-bsl.git
cd ludus-source-bsl
git sparse-checkout set templates/<template-dir-name>
git submodule update --init templates/<template-dir-name>   # if it's a submodule
```

## 4. Re-register it — plain uncompressed tar, not `.tgz`

```bash
cp -r templates/<template-dir-name> templates/<full-template-name>   # rename to match e.g. "-template" suffix
cd templates
tar --format=ustar -cf /tmp/<name>.tar <full-template-name>
```

```
mcp__ludus__call_ludus_api addTemplateFromTar, body {"file": "/tmp/<name>.tar", "force": false}
```

**A gzip-compressed `.tgz` is rejected** with `400: Invalid tar archive:
archive/tar: invalid tar header` — this endpoint wants a plain `.tar`
(unlike `InstallRoleTar` for custom Ansible roles, which accepts `.tgz`
fine). Confirm via `getTemplates` that it now shows `built: false` (i.e.
registered but not yet built) before proceeding.

## 5. Build it

```
mcp__ludus__call_ludus_api buildTemplates, body {"templates": ["<full-template-name>"], "parallel": 1}
```

Poll `getTemplatesStatus` (empty/`null` response = done) and `getTemplates`
(`built: true`) for completion. Check `getPackerLogs` on any failure —
long-running Windows Update polling over WinRM is a known source of
transient build failures (`WSManFaultError: InvalidSelectors`) unrelated to
the template source itself; a plain retry of `buildTemplates` is reasonable
for that specific symptom.

## 6. Redeploy

Once `built: true`, any range referencing this template by name can just be
redeployed (`deployRange`) — no config changes needed, since the template
name didn't change.
