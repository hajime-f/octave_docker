main:
	docker tag octave_python:latest $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/octave_python:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/octave_python:latest
dev:
	docker-compose -f docker-compose.dev.yml build
prod:
	docker-compose -f docker-compose.prod.yml build
up:
	docker-compose -f docker-compose.dev.yml up -d
down:
	docker-compose -f docker-compose.dev.yml down
stop:
	docker-compose -f docker-compose.dev.yml stop
vue:
	docker-compose -f docker-compose.dev.yml run vue npm run build
serve:
	docker-compose -f docker-compose.dev.yml run vue npm run serve
login:
	aws ecr get-login-password --region ap-northeast-1 --profile fujita | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com
clean:
	docker-compose -f docker-compose.dev.yml rm
	docker-compose -f docker-compose.prod.yml rm
app:
	docker-compose -f docker-compose.dev.yml run python ./manage.py startapp $(APP_NAME)
migrate:
	docker-compose -f docker-compose.dev.yml run python ./manage.py makemigrations
	docker-compose -f docker-compose.dev.yml run python ./manage.py migrate
all_clear:
	docker-compose -f docker-compose.dev.yml down
	docker volume rm octave.db.volume
	find ~/Development/private/ -path "*/migrations/*.py" -not -name "__init__.py" -delete
	find ~/Development/private/ -path "*/migrations/*.pyc" -delete
commit:
	@echo "Running git on octave_docker"
	git add -A .
	git commit -m $(COMMENT)
	git push origin master
	cd "$(PWD)/src" && make commit $(COMMENT)
