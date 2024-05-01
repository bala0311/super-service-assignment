# Define variables
$projectName = "super-service"
$publishFolder = "publish"
$imageName = "super-service-image"

# Step 1: Run unit tests
dotnet test --logger "trx;LogFileName=test_results.trx"

# Step 2: Create a Dockerfile
@"
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["$projectName.csproj", "."]
RUN dotnet restore "$projectName.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "$projectName.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "$projectName.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$projectName.dll"]
"@ | Out-File -Encoding Ascii Dockerfile

# Step 3: Build the Docker image
docker build -t $imageName .

# Step 4: Run the Docker container
docker run -d -p 8080:80 --name $projectName $imageName
