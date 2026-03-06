# TailTrail
316 Group Project
Overview: 

Creating an app to help people find their lost pet. This App will include a Login/Logout form, a map that you can pin sightings/missing dog in your area and a search function to help find your dog in the area. Along with this a database will store your login info and map meta data so it remains persistent, as well as keywords from forums to enhance searchability for users. 

*Commented out lines ‘ // ‘ are future enhancements for the app that are time dependent on the project.

Architecture:

- SwiftUI
- Firebase
- MapKit
- Role-based access (Free vs Member)

---

USER TYPES

Free Users:

1. View all lost pet posts on the map.
2. Use search to filter posts by keywords.
3. Toggle between Lost and Spotted posts.

Members:

1. Everything Free users can do.
2. Post lost animals.
3. Post spotted animals.
4. Drop a pin on the map when creating a post.
5. Upload a photo.
6. Message other users.

---

NAVIGATION STRUCTURE

Bottom Tab Bar:

1. Map (Home)
    - Main map screen
    - Search bar at top
    - Toggle (Lost / Spotted)
    - Clustered pins
    - Zoom-based splitting

1. Post
    - If user is NOT logged in → show sign up prompt
    - If logged in:
        - Select Lost or Spotted
        - Drop pin on map
        - Fill out form
        - Upload image (camera or gallery)
        - Submit
2. // Messages
    - // List of conversations
    - // Tap into chat thread
    - // Real-time messaging
3. Profile
    - If not logged in → Sign up / Login
    - If logged in:
        - View profile info
        - Toggle membership status (future feature)
        - View personal posts
        - Logout

---

MAP BEHAVIOR

// When Zoomed Out:

- // Clustered pins
- // Shows number of posts in that area

// When Zooming In:

- // Clusters split apart
- // Eventually show individual pins

Pin Style:

- Circular image thumbnail of pet
- Small pin indicator under image
- Different color for:
    - Lost (Red)
    - Spotted (Blue)

Map Filters:

- Toggle button to switch between Lost and Spotted
- Search bar filters visible posts
- Matching results highlight pins

---

FILE STRUCTURE

PetFinder/

App/

- PetFinderApp.swift

Core/

- Models/
    - PetPost.swift
    - AppUser.swift
    - Message.swift
- Services/
    - AuthService.swift
    - PetService.swift
    - MessagingService.swift
    - LocationService.swift

Features/

- Map/
    - MapView.swift
    - MapViewModel.swift
    - PetAnnotation.swift
- Post/
    - CreatePostView.swift
    - CreatePostViewModel.swift
- Profile/
    - ProfileView.swift
    - ProfileViewModel.swift
- Messaging/
    - ChatListView.swift
    - ChatView.swift
    - ChatViewModel.swift
- Components/
    - SearchBar.swift
    - PostTypeToggle.swift

---

CORE DATA MODELS

PetPost:

- id
- title
- description
- imageURL
- latitude
- longitude
- type (lost / spotted)
- ownerID
- timestamp

AppUser:

- id
- email
- isMember

Message:

- id
- senderID
- receiverID
- text
- timestamp

---

POST CREATION FLOW

1. User taps Post tab.
2. Check authentication.
3. Choose Lost or Spotted.
4. Map appears for selecting location.
5. Fill out Form:
    - Title
    - Description
    - Image
6. Submit.
7. Save to backend.
8. Refresh map.

---

SEARCH FUNCTIONALITY

Search bar filters by:

- Breed
- Color
- Name
- Keywords in description
