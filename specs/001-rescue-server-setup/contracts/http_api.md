# API Contract: File Server

**Protocol**: HTTP/1.0 or HTTP/1.1
**Method**: GET

## Endpoints

### `/` (Root)
- **Description**: Returns the dashboard HTML.
- **Response**: `200 OK` (text/html).

### `/scripts/*`
- **Description**: Returns file contents from scripts directory.
- **Response**: `200 OK` (application/octet-stream or text/plain).

### `/manuals/*`
- **Description**: Returns file contents from manuals directory.
- **Response**: `200 OK` (application/pdf or text/plain).

### `/drivers/*`
- **Description**: Returns file contents from drivers directory.
- **Response**: `200 OK` (application/octet-stream).

## Error States
- **404 Not Found**: If file does not exist.
- **403 Forbidden**: If file permissions prevent reading.
