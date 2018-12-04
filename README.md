# Step wercker-oracle-accs-deploy
Wercker step to deploy application (Java, NodeJS, PHP, Python) to Oracle Application Container Cloud Service.

# Options

- `opc_user` user name for your Oracle Application Container Cloud account.
- `opc_password` password for your Oracle Application Container Cloud account.
- `rest_url` e.g.: `https://apaas.europe.oraclecloud.com/paas/service/apaas/api/v1.1/apps` Locate Oracle Application Container Cloud in the My Services console, click Details, and look at the REST Endpoint value.
- `domain` Name of the identity domain for the Oracle Application Container Cloud Service account.
- `application_name` Name of the application.
- `application_type` Runtime of the application (e.g.: java).
- `file` Name of the application archive (zip artifact).
- `subscription_type` The type of ACCS subscription you have (Hourly|Monthly) for deployment purposes.

# Example

	box: combient/java-mvn
	build:
	  steps:
	    # Build application
	    - script:
	        name: Maven install
	        code: mvn install
	deploy-accs:
	  steps:
	    # Deploy to Oracle Application Container Cloud
	    - thebeebs/oracle-accs-deploy:
	        opc_user: $OPC_USERNAME
	        opc_password: $OPC_PASSWORD
	        rest_url: $REST_URL
	        domain: $IDENTITY_DOMAIN
	        application_name: springboot-accs-demo
		application_type: java
	        file: springbootdemo-0.0.1.zip
	        subscription_type: Hourly


This will copy the binary (zip artifact) to the storage container cloud service than deploy to application container cloud service.
