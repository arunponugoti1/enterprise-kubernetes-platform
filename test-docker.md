---
  🟢 Easy (measuring surface)

  Q1. In your own words — what is a Docker container? If your mom asked you "what is this docker thing you keep talking about," what would you say?
  ans: docker container is like a full package bag , for example every day i go to the office , do i use one bag for the charding, do i use  one bag for lap, one for lunch? no right, for all i keep in one collage bag with seprate sections and keep it with zip, same like the application code, libraires, dependencies, runtime envs, env variables , pot num etc all are required to run one applcaition but it is ok for the local but if you ship this and run it to another guy's lap it is very diffcult to share, if some thing missing , app will not up so the container is resolving this issue we will package as a one box that is imagem and run it at a time that is container , it will run one by one at a time in the any server , any cloud

  Q2. What's the difference between a Docker image and a Docker container? Give an analogy.
  ans: docker image is a template or rule book to run the applciation , where what exsit what first should run like , in the bag first you opne the lunch box when you reach office, then open laptop the charger , like this, container is like a server runtime , it will execute all the instructions using docker image , docker container required cpu, memory to run the docker iamge , like it is a combination docker image, docker runtime env, cpu, memory

  Q3. Look at your project's docker-compose.yml (you don't need to open it — just from memory). What does docker-compose up actually do? List the steps you
  think happen behind the scenes.
  ans: docker compose is like a manager who manage the containers , what should what, what should connect to which one , it is like a runtime , it will helps to run all the microservice
  it is like a automation pipeline it runs all the containers at a time,
  ---
  🟡 Medium (measuring working knowledge)

  Q4. A Dockerfile has 10 lines. You change line 8 and rebuild. Which lines get re-executed, which get cached, and why? What rule determines this?
  ans: it is like layer base docker image creation , it runs layer by layer, if you change line 8 and rebuild next time it will start from the line you changed

  Q5. In your docker-compose.yml, the account-service probably talks to a postgres (or similar) container. How does account-service find postgres? What does it
  use as the "address"? Why does that magic work?
  Ans: we are giving the postgress info to the account service with host name, username, password and then while running the account service by docker compose then it will resolve  the dns using env variables by user inputs and give it to the accountservice
  i think i gave jus random understadning , if you ask me to proove i can't 

  Q6. What's the difference between these three?
  - COPY vs ADD in a Dockerfile
  - A volume vs a bind mount
  - EXPOSE 8080 vs -p 8080:8080
  ans: Copy means if we want to copy any files from local wto the docker file weuse it , i don;t kno about ADD command
  volume means a storage directory here we put our applcaition data which was created, it is like a data storage bucket disk kind of , 
  bind mount is like a communication network from applcaition to volume the data flow , from this wat data tranfer happening from app to volume, voulme to app
  - Expose 8080 is like adding this command inthe docker file so this applcition opens for the port 8080, the microservice will use the port 8080 by default 
  - -p 8080:8080 means local host: container port , you can't open applcaition in browser with container port by default , the dockeer network won't support so we have to make the connection beetween local to container with local active port

  Q7. Your colleague says: "I built the image on my laptop, it's 1.2 GB. Can we make it smaller?" What are 3 things you would check or change? (No need to write
   code — just the techniques.)
   so here he is using single stage docker file thats why it is more size, if he asks to reduce we can use multi stage docker file by elemicatiing unneccessory things like dependencies, run time envs base image for installing the software and create new 2nd stage where we can choose lightweght base image and copy the installed files only and copy the app code thast it it will reduce the size

  ---
  🔴 Hard (measuring depth — the level you need for K8s)

  Q8. A container is "isolated" from the host. What is actually doing the isolation? Is it Docker? The Linux kernel? Something else? Name the specific
  mechanism(s) if you know them.
  ans: i heard somewhere we use c-groups, namespaces of the linux machines concepts , but i don;t know what they are , why we use, how they create , where we do create them , stay? if you ask me to prove i can't 

  Q9. Production scenario: A container in your project keeps restarting every 30 seconds. docker ps shows it as "Restarting." How do you debug this? Walk me
  through your steps — what commands, what you'd look for, in what order.
  ans: we see the logs then events and check cpu, memory 

  Q10. When Kubernetes runs a Pod with 2 containers, those containers can talk to each other on localhost:port. How is that possible if they're "separate
  containers"? What is Kubernetes doing under the hood, and can you achieve the same thing with plain Docker? (Bonus if you can name the trick.)
  ans: pod is running as a single machine and inside two containers are running so they treat as local for both and they talk to each other with localhost:port , like a docker network