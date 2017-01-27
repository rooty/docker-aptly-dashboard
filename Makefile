VERSION ?= latest
REGISTRY ?= docker.io
BRANCH ?= master

default: build

clean:
	docker rmi $(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION)
	docker rmi $(REGISTRY)/bborbe/aptly-dashboard:$(VERSION)

setup:
	mkdir -p ./go/src/github.com/bborbe/aptly_dashboard
	git clone -b $(BRANCH) --single-branch --depth 1 https://github.com/bborbe/aptly_dashboard.git ./go/src/github.com/bborbe/aptly_dashboard
	go get -u github.com/Masterminds/glide
	cd ./go/src/github.com/bborbe/aptly_dashboard && glide install

buildgo:
	CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o aptly_dashboard_server ./go/src/github.com/bborbe/aptly_dashboard/bin/aptly_dashboard_server

build:
	docker build --build-arg VERSION=$(VERSION) --no-cache --rm=true -t $(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION) -f ./Dockerfile.build .
	docker run -t $(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION) /bin/true
	docker cp `docker ps -q -n=1 -f ancestor=$(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION) -f status=exited`:/aptly_dashboard_server .
	docker cp `docker ps -q -n=1 -f ancestor=$(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION) -f status=exited`:/go/src/github.com/bborbe/aptly_dashboard/files .
	docker rm `docker ps -q -n=1 -f ancestor=$(REGISTRY)/bborbe/aptly-dashboard-build:$(VERSION) -f status=exited`
	docker build --no-cache --rm=true --tag=$(REGISTRY)/bborbe/aptly-dashboard:$(VERSION) -f Dockerfile.static .
	rm -rf aptly_dashboard_server files

run:
	docker run \
	-p 8080:8080 \
	-e PORT=8080 \
	-e ROOT=/files \
	-e API_PREFIX= \
	-e REPO_URL=http://aptly.benjamin-borbe.de \
	-e API_URL=http://aptly.benjamin-borbe.de \
	-e API_USERNAME= \
	-e API_PASSWORD= \
	$(REGISTRY)/bborbe/aptly-dashboard:$(VERSION) \
	-logtostderr \
	-v=0

upload:
	docker push $(REGISTRY)/bborbe/aptly-dashboard:$(VERSION)
