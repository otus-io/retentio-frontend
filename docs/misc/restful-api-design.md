🌐 [English](restful-api-design.md) | [中文](restful-api-design_zh.md)

---

# Design Decisions

This document records key design decisions made in the WordUpX project and the reasoning behind them.

---

## Why RESTful API Over a Unified/RPC Endpoint

When designing the API, we evaluated two approaches: **standard RESTful URLs** (e.g., `GET /decks/5`, `DELETE /cards/2`) and a **unified/RPC endpoint** (sending IDs and operations in the request body, handling all requests through a single endpoint like `POST /api/endpoint`).

We chose the RESTful style for the following reasons — a unified/RPC endpoint has these potential issues:

### 1. Zero Caching (Performance Hit)

Browsers and CDNs rely on **URLs** and **GET requests** to cache data. Since RPC-style uses `POST` for everything, the browser cannot cache the response. This means the server must re-process the exact same request every time a user views a page, causing unnecessary performance overhead.

### 2. "Black Box" Logging (Poor Observability)

Your server access logs become useless. Instead of seeing clear entries like `GET /decks/5` or `DELETE /cards/2`, every log entry looks identical: `POST /api/endpoint`. You cannot easily troubleshoot bugs, track traffic patterns, or see which resources are most popular without building complex custom logging.

### 3. Security Blind Spots

Web Application Firewalls (WAFs) are optimized to **scan URLs** for malicious patterns (like SQL injection). If you bury your IDs and commands deep inside a JSON body, standard security tools may miss attacks that they would otherwise block automatically.

### 4. Broken Error Handling

In RPC, the HTTP status is usually always `200 OK` (meaning the message reached the server), even if the operation failed (e.g., "Card not found"). This breaks standard monitoring tools that rely on status codes like `404` (Not Found) or `401` (Unauthorized) to alert you to problems. RESTful APIs properly leverage HTTP status codes, making monitoring and error tracking intuitive and standardized.
