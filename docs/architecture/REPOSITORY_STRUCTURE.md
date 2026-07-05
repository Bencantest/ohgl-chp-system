# Frontend Relocation Note

The current frontend entrypoint remains at repository root (`index.html`) with source modules in `src/` to preserve existing static hosting and imports.

A future restructuring may move these files under `frontend/`, but that should be handled as a dedicated refactor with deployment updates and regression testing.
