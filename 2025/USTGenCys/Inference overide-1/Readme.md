# Web Application Security Assessment Writeup
<img width="689" height="610" alt="image" src="https://github.com/user-attachments/assets/9efb4e9b-444a-46af-96c9-d5b36f27526e" />


## Step 1: Initial Reconnaissance - The `robots.txt` File
The first step in any web application assessment is enumeration. I began by checking the `robots.txt` file, which often contains clues about the site's structure or hidden directories. In this case, it revealed two key pieces of information:

- A non-standard endpoint: `/internal-api/`.
- A comment or another disallowed entry that hinted at a gold access tier.

Navigating to the `/internal-api/` endpoint presented a page titled **"Restricted Internal Storefront."** This page explicitly mentioned a **"mistakenly exposed Postman collection containing internal API calls"** and provided a link to download it. This was a critical **information disclosure vulnerability**.

---
<img width="1041" height="733" alt="image" src="https://github.com/user-attachments/assets/3be8bccc-5637-47bd-b3aa-67159866978a" />


## Step 2: Analyzing the Leaked Postman Collection
After downloading and importing the collection into Postman, I examined the requests it contained. The collection detailed a request to an internal API endpoint designed to fetch credentials:

```json
{
  "info": {
    "_postman_id": "12345-abcdef-ctf-creds",
    "name": "Internal Credentials",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get Credentials",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "http://localhost:8080/api/creds.php",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8000",
          "path": ["api", "creds.php"]
        }
      },
      "response": []
    }
  ]
}
```
The key piece of information here was the URL: http://localhost:8080/api/creds.php. While this pointed to a local development server and was not directly accessible, it revealed the existence and structure of an internal API.

## Step 3: Pivoting and Exploiting the Public-Facing Application
The application's main interface showed a "Deals" page for a logged-in user, johndoe, who had a "default" tier status. The URL for this page was https://inference.agencycorp.in/deals.php.
Armed with the hint about a "gold" tier from the robots.txt file, I decided to test if I could access it by manipulating the URL. I appended a parameter based on the hint.
I changed the URL from:
`https://inference.agencycorp.in/deals.php`
to:
`https://inference.agencycorp.in/deals.php?tier=gold`
This successfully elevated my privileges and granted me access to the "Gold" tier deals, solving the challenge.

### Root Cause Analysis: Why This Worked
<img width="1042" height="382" alt="image" src="https://github.com/user-attachments/assets/b088260c-4a8e-41f2-bf5b-8a5b3b0e452f" />

This exploit was successful due to a critical vulnerability known as **Insecure Direct Object Reference (IDOR)**, combined with initial information disclosure.

**Information Disclosure**: The exposed robots.txt file and the Postman collection were the first mistakes. They gave away the internal API structure, naming conventions, and different access levels, providing a clear roadmap for the attack.

**Broken Access Control (IDOR)**: The application's backend trusted user-supplied input (tier=gold) to determine the user's authorization level. There was no server-side validation to check if the currently logged-in user, johndoe, was actually supposed to have "gold" tier access. The application blindly granted access based on the parameter provided in the URL.

A secure application should have determined the user's tier based on their session information stored on the server, not from a parameter that the user can control.


