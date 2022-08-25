# Tutorial: https://docs.microsoft.com/en-us/azure/storage/blobs/use-azurite-to-run-automated-tests


# STEP 1 & 2: Manually install latest verison of Python and Azure Storage Explorer




#region "STEP 3: Install and run azurite"
# Install Azurite if not already installed
if(!(npm list -g -p azurite)){
    npm install -g azurite
}

# Create an Azurite directory
mkdir .\azurite

# Launch Azurite locally
azurite --silent --location .\azurite --debug .\azurite\debug.log
#endregion



# STEP 4: In Azure Storage Explorer, select Attach to Resource > Select Resource > Local storage emulator



# STEP 5: Provide a Display name and Blobs port number to connect Azurite and use Azure Storage Explorer to manage local blob storage.



# STEP 6: Create a virtual Python environment
python -m venv .venv




# STEP 7: Create a container and initialize environment variables. Use a PyTest conftest.py file to generate tests. Here is an example of a conftest.py file:
python .\7_container.py




# "STEP 8: Install dependencies listed in a requirements.txt file"
pip install -r requirements.txt



# "STEP 9: Run tests"
python .\tests