# Entity access v2

```txt
invite/<entity_type>/invide_id/<inviteId>/
    - entityId: entityxyz
invite/<entity_type>/invite_id/<inviteId>/invite_entity/<entity_id>/
    - entity:
       - active: true
       - name: <name>
    - entityId: <entity_id>
    - timestamp: <timestamp>
    - userAccess:
        - read: true
        - write: true
        - admin: true
        - role: <custom>
```

# Entity access

For a top root entity such as `app` you have the following firestore structure:

```txt
- app:
  - app1: # app id
      some: data
  - app2: # app id
      some: data
- app_access
  - app1: # app id
    * public: true (default)
    - user:
        - user1:
            read: true
            write: true
            admin: true
            role: <custom>
        - user2:
            read: true
            write: false
            admin: false
            role: <custom>
  - app2: # app id
    - user:
        - user1:
            read: true
            write: true
            admin: true
            role: <custom>
        - user2:
            read: true
            write: false
            admin: false
            role: <custom>
```