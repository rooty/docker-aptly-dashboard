default: build

clean:
	docker rmi bborbe/aptly-dashboard-build
	docker rmi bborbe/aptly-dashboard

setup:
	go get github.com/bborbe/aptly_dashboard/bin/aptly_dashboard_server

buildgo:
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o aptly_dashboard_server ./go/src/github.com/bborbe/aptly_dashboard/bin/aptly_dashboard_server

build:
	docker build --no-cache --rm=true -t bborbe/aptly-dashboard-build -f ./Dockerfile.build .
	docker run -t bborbe/aptly-dashboard-build /bin/true
	docker cp `docker ps -q -n=1 -f ancestor=bborbe/aptly-dashboard-build -f status=exited`:/aptly_dashboard_server .
	docker cp `docker ps -q -n=1 -f ancestor=bborbe/aptly-dashboard-build -f status=exited`:/go/src/github.com/bborbe/aptly_dashboard/files .
	docker rm `docker ps -q -n=1 -f ancestor=bborbe/aptly-dashboard-build -f status=exited`
	mkdir -p tmp
	docker build --no-cache --rm=true --tag=bborbe/aptly-dashboard -f Dockerfile.static .
	rm -rf aptly_dashboard_server files tmp

run:
	docker run -p 8080:8080 -e PORT=8080 -e LOGLEVEL=debug -e ROOT=/files -e API_PREFIX= -e REPO_URL=http://aptly.tools.seibert-media.net -e API_URL=http://aptly.tools.seibert-media.net -e API_USERNAME= -e API_PASSWORD= bborbe/aptly-dashboard

upload:
	docker push bborbe/aptly-dashboard
