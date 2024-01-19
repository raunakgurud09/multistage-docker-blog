# Dockerize Typescript app

This blog post explores the process of dockerization a TypeScript Express app while taking into consideration best practices. It showcases the usage of multistage Docker files to optimize the Dockerization process.

This is not on basic of docker it will deep dive into optimize way to write Dockerfile to improve performance security speed

let's start by building a simple express app using typescript

```bash
    mkdir ts-docker
    cd ts-docker
    
    # Initialize project
    npm init
    
    # Add dependencies 
    yarn add express
    
    # Add dev dependencies
    yarn add -D typescript @types/express @types/node
    
    # Preinstalled tsc globally
    tsc --init 
    
    # Change tsconfig.json 
    "rootDir": "./src",    
    "outDir": "./dist",                     
    
    # start the server
    npm run build
    npm run start
```

src/index.ts

![setup-basic-express](/public/images/setup-basic-express-app.png)

The provided TypeScript code sets up a basic Express.js server. It creates an Express app, defines a health check endpoint (/health), and starts the server on a specified port.

```bash
    npm run build
```

![setup-package-json](/public/images/setup-package-json.png)

Build scripts simply compile the TypeScript code into JavaScript and output it into the "dist" folder. You will now observe a "/dist" folder created.

```bash
npm run start
```

![setup-console](/public/images/setup-console.png)

The server is currently running on PORT 8090 in your local system. You can check the health of the system by using the following route: [http://localhost:8090/health](http://localhost:8090/health)

![setup-health](/public/images/setup-health.png)

If you see this message, it indicates that everything is functioning properly ✨✨.

Now, let's move to the next phase and dockerize it. Kindly close the server by using the command \`*Ctrl + C*\` .

## Dockerization app

create a filename `Dockerfile` please ensure that you use the exact filename provided

```dockerfile
# Base image
FROM node:18

# Setup workdir
WORKDIR /usr/app

COPY package*.json .

# Install Dependencies
RUN npm install

# Copy Application Code
COPY . .

# Build Application
RUN npm run build

# Run Command
EXPOSE 8090
CMD node dist/index.js
```

1.*Base Image:** Specifies that this image is based on the official Node.js 18 image, which includes Node.js and npm.

```powershell
    FROM node:18
```

2.**Working Directory:** Sets the working directory inside the container to `/usr/app`.

```powershell
    WORKDIR /usr/app
```

3.**Copy Package Files:** Copies the package.json and package-lock.json files into the working directory.

```powershell
    COPY package*.json .
```

4.**Install Dependencies:** Runs the `npm install` command to install the dependencies specified in the package.json file.

```powershell
    RUN npm install
```

5.**Copy Application Code:** Copies the rest of the application code into the working directory.

```powershell
    COPY . .
```

6.**Build Application:** Executes the `npm run build` command to build the application. This assumes there is a build script specified in the package.json file.

```powershell
    RUN npm run build
```

7.**Expose Port:** Informs Docker that the application inside the container will use port 8090.

```powershell
    EXPOSE 8090
```

8.**Run Command:** Specifies the default command to run when the container starts. It runs the Node.js application from the `dist` directory (assuming the build output is there).

```powershell
    CMD node dist/index.js
```

To ignore files in your Docker build, you can add them to the .dockerignore file.

```bash
touch .dockerignore
```

![setup-dockerignore](/public/images/setup-docker.png)

Here are the files and folders that should be ignored after the build process:

* /dist
* /node\_modules

> [!NOTE]  
> Make sure you have Docker installed and running on your system.

Now let's build the image

**What is a Image ??**
Images are typically built from a set of instructions provided in a special file called a Dockerfile. This file defines the base image, sets up the working directory, copies files into the image, installs dependencies, and specifies the commands to be run.

To build an image, use the following command

```powershell
    docker build -t [tag-name] .
```

In this command, the , -t, flag is used to provide a tag name for the image.

![docker-image-explain](/public/images/docker-image-explain.png)

Go to console and type

```bash
    docker build -t ts-docker/single .
```

> [!NOTE]  
> Building an image can be time-consuming if you do not have the base image already installed. Be patient 🧘‍♂️

![build-console-single](/public/images/build-console-single.png)

To execute the build image within a container, utilize the subsequent Docker command

```powershell
    docker run -it -p [external port]:[internal port] --name [container name] [image ID or tag name]
```

* ( -it) : This option enables an interactive mode for the container and allocates a pseudo-TTY. It allows you to interact with the container's command-line interface.
* (-p) : \[external port\]:\[internal port\] : This option maps an external port to an internal port of the container. Replace , \[external port\], with the desired port on your host machine and , \[internal port\], with the corresponding port inside the container.,
* (--name) \[container name\] : This option assigns a specific name to the container. Replace , \[container name\], with your desired name.
* \[image ID or tag name\] : This is the ID or tag name of the Docker image you want to use for creating the container.

To run the build image of your application in a container, use the following Docker command:

```bash
    docker run -it -p 8090:8090 --name single ts/single
```

This Docker command runs a container named "single" from the "ts/single" image. It allocates a terminal (-it), maps port 8090 on the host to port 8090 in the container (-p 8090:8090), allowing interaction with the containerized TypeScript application.

![run-console-single](/public/images/run-console-single.png)

If you can see this message, congratulations!

You have successfully created a Docker image with a TypeScript Express app. To verify its functionality, please visit the "/health" route of the server.

## The issues with the normal container.

The current issue lies in the excessive size of the Image. Despite avoiding the utilization of numerous packages, the Docker image size reaches a staggering 1.14GB. This contradicts the fundamental objective of containerizing the application into a compact file, as it essentially transforms into a virtual machine (VM).

![size-single](/public/images/size-single.png)

Let's explore the steps to resolve these issues.

### 1. Using && instead of 2 RUN Commands

When building Docker containers, aim for smaller images. Shared layers and smaller sizes lead to faster transfer and deployment. But how do you manage size when each RUN statement creates a new layer and intermediate artifacts are needed? Many Dockerfile use unconventional techniques to address this issue.

```bash
    FROM ubuntu

    RUN apt-get update && apt-get install vim
```

Why the `&&`? Why not running two `RUN` statements like this?

```bash
    FROM ubuntu

    RUN apt-get update
    RUN apt-get install vim
```

Docker layers store the difference between image versions. Like git commits, they are useful for sharing with other repositories or images. When you request an image, you only download the layers you don't already have, making sharing more efficient. However, layers use space and increase the size of the final image. Combining multiple RUN statements on a single line was a common practice.

We have already implemented this point, so there is no need to worry. Now, let us explore other areas for improvement.

### 2. Multistage docker builds

When creating Docker images for applications, developers often need additional tools and dependencies during the build process that are not required for the final runtime image. Including these unnecessary elements in the final image can result in larger image sizes, which may impact performance and security.

![multi-stage-process-1](/public/images/multi-stage-process-1.png)

Traditional Docker app.

*What is docker multistage?*

Docker multistage builds are a feature that allows you to use multiple `FROM` statements in a single Dockerfile. This enables you to build and compile your application in one stage and then copy only the necessary artifacts into a smaller and more efficient image for runtime in the final stage. The primary goal is to create smaller Docker images by eliminating unnecessary build dependencies and files.

![multi-stage-process-2](/public/images/multi-stage-process-2.png)

Using multistage build

This Dockerfile utilizes multistage builds to separate the build and runtime environments effectively. In the first stage, the application is compiled and built, while the second stage focuses on creating a smaller and more efficient image specifically for running the application. By adopting this approach, the final image size is reduced, unnecessary build artifacts are excluded from the runtime environment, and both security and efficiency are enhanced.

Below is a simplified example of a Dockerfile that demonstrates the use of multistage builds for your application

Now we understand that Typescript is essential during the development process only. We can utilize Typescript to build the JavaScript file during the builder stage and then use the generated JavaScript file in the next phase, known as the runner stage.

**Stage 1: Build Stage**

```bash
    # Use Node.js 18 as the base image for the builder stage
    FROM node:18 as builder

    WORKDIR /build

    COPY package*.json .
    RUN npm install

    COPY . .

    RUN npm run build
```

* The first stage involves setting up the build environment, also known as the builder. This builder can be utilized in subsequent stages for further development.
* To generate the corresponding JS code in the builder phase, I copied the `package.json`, `package-lock.json`, and `src` files.
* We have executed ,npm run build, which will generate a ,/dist, folder containing all the required JS files.

**Stage 2: Runtime Stage**

```powershell
    # Use Node.js 18 as the base image for the runtime stage
    FROM node:18 as runner

    # Set the working directory within the container to /app
    WORKDIR /app

    # Copy package.json from the build stage to the working directory
    COPY --from=builder build/package*.json .
    COPY --from=builder build/dist dist/
    COPY --from=builder build/.env .

    # Install only production dependencies
    RUN npm install --only=prod

    # Define the command to run the application
    CMD [ "npm", "start" ]
```

* The second stage (`runner`) also uses Node.js version 18 as the base image but is intended for the runtime environment.
* It sets the working directory within the container to `/app`.
* `package.json` and package-lock.json is copied from the `build` stage to the working directory to ensure the correct production dependencies are available.
* The `dist`, and `.env` files are copied from the `builder` stage to the working directory /app.
* The RUN command(--only=prod) is used to install only the production dependencies, effectively reducing the size of the image.

Now let's create the image again using this multistage statergy in your application

Please update your Dockerfile with the code provided below.with code given below

![dockerfile-multi](/public/images/dockerfile-single.png)

Build The image with new \[tag-name\]. Here you can give any name as your wish we are gonna use t*s-docker/multistage*

Go to console and type:

```bash
    docker build -t ts-docker/multistage .
```

Output:
![build-console-multistage](/public/images/build-console-multistage.png)

Use the updated image to run the container.

```bash
    docker run -it -p 8090:8090 --name multistage ts-docker/multistage
```

![run-console-multi](/public/images/run-console-multi.png)

If you see this, you have successfully created a Docker image using a multistage build. You can check by going to the /health route of the server.

Now, let's take a look at the size of the image

![size-multi](/public/images/size-multi.png)

In this case we have only removed the src/ directory and the devDependency packages containing all the code realated to typescript

The size is reduces but we still have the same problem the image is too big

(1.14 GB) --&gt; (1.1 GM)

Using multistage builds is a highly effective approach to decreasing the final image size and eliminating unnecessary components from the runtime image. By doing so, it contributes to enhancing security and efficiency in your workflow.

What else can we do to reduce the size of image. Let see

### 3. Using slim version of runtime

By analyzing the code, it is evident that there is no further content that can be eliminated. However, even after removing excess content, the image size remains excessively large. Therefore, based on first principles, it can be deduced that the root issue lies in the initial size of the node base image.

The current image includes Node.js, yarn, npm, bash, and other binaries. It is based on Ubuntu, providing a fully fledged operating system. However, when running a container, only Node.js is necessary. Docker containers should only contain the essential components to run a single process, without needing an operating system. In this case, everything except Node.js could be removed.

By using smaller base images with Alpine

In other words, a Linux distribution that is smaller in size and more secure.

You shouldn't take their words for granted. Let's check if the image is smaller.

You should tweak the `Dockerfile` and use `node:alpine`

![dockerfile-alpine](/public/images/dockerfile-alpine.png)

Create a image for this Dockerfile config.

Go to console and type:

```bash
    docker build -t ts-docker/alpine .
```

![build-console-alpine](/public/images/build-console-alpine.png)

Now, let's take a look at the size of the image

![size-alpine](/public/images/size-alpine.png)

Yaayy!!! 🥳🥳 as you can see the size of the image is now 147 MB from 1.1 GB

![size-all](/public/images/size-all.png)

Transitioning from a larger Node.js image in the build stage to a more streamlined Alpine-based image in the runtime stage significantly trims the overall image by almost 1 GB. The Alpine base contains only the essential commands for execution, enhancing efficiency and minimizing the container's footprint, resulting in a more optimized and lightweight deployment.

**What have we achieved:**

1. **Smaller Image Size:** image is lightweight, resulting in significantly reduced image sizes, promoting faster downloads, and efficient resource utilization.
2. **Enhanced Security:** Alpine is designed with security in mind, offering a minimal and secure environment, reducing the attack surface, and including security-focused components like Musl libc and BusyBox.
3. **Container Best Practices:** Aligns well with containerization best practices, emphasizing simplicity, minimizing unnecessary components, and ensuring cleaner and more efficient Dockerfile with multistage approach
4. **Faster Builds and Deployment:** Smaller images lead to faster build times and quicker deployments, especially beneficial in CI/CD pipelines and scenarios requiring rapid scaling.

In conclusion, whether optimizing Docker images, implementing multistage builds, or choosing a specific Node.js image, the overarching goal is efficiency, security, and adherence to best practices.

🚀 If you had a blast exploring. Stay tuned for the next blog where we'll explore more such topics. Don't forget to share this blog with your tech-savvy pals! Together, we're coding our way to greatness. 🚀💻

Follow me @[Raunak Gurud](@raunakgurud2002) ❤️⚡