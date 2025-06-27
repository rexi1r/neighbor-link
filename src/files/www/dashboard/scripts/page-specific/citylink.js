const connectButton = document.getElementById("connect-btn")
const disconnectButton = document.getElementById("disconnect-btn")
const connectionString = document.getElementById("connection-string")

connectButton.onclick = async function(e){
    showLoadingConnectButton(true)
    const params = validateAndParse(connectionString.value)
    if( params == false )
    {
        addCustomAlert("Invalid String","Please make sure you copy the correct string, It should start with InR and end with @domain or @server_ip",10000)
        showLoadingConnectButton(false)
        return;
    }

    const result = await async_lua_call("dragon.sh","infinite-reach-connect "+params["SERVER_IP"]+" "+params["DEFAULT_CHISEL_PORT"]+" "+params["INT_PORT1"]+" "+params["EXT_PORT2"]+" "+params["EXT_PORT1"]+" "+params["SERVER_IP_TYPE"]+" "+params["CLIENT_KEY"]+" "+params["PASSWORD"])
    const resultSplit = result.split(" ")
    if ( resultSplit[0] == "running" && (resultSplit[1] == "Connected" || resultSplit[1] == "Connecting") ){
        changeStatus(resultSplit[1].toLowerCase(),"Server://"+params["SERVER_IP"])
        if(resultSplit[1] == "Connecting"){
            loading(true,"Connecting...")
            checkCitylinkLoop(params["SERVER_IP"])
        }
    } else {
        addCustomAlert("Something Went Wrong.","Please try Again.",6000)
    }
    showLoadingConnectButton(false)
}

disconnectButton.onclick = async function(e){
    loading(true,"Disconnecting...",true);
    const result = await async_lua_call("dragon.sh","infinite-reach-disconnect")
    const resultSplit = result.split(" ");
    if ( resultSplit[0] == "inactive"){
        changeStatus("disconnected","")
        loading(false);
        return;
    }
    addCustomAlert("Something Went Wrong", "Please make sure your iran internet is working and try agaign",5000)
    loading(false);

}

getStatus_iReach();
async function getStatus_iReach(show = true) {
    if(show) loading(true,"Getting Status...");
    const result = await async_lua_call("dragon.sh","infinite-reach-status")
    const resultSplit = result.split(" ");
    if ( resultSplit[2] == "running" && (resultSplit[3] == "Connected" || resultSplit[3] == "Connecting")){
        changeStatus(resultSplit[3].toLowerCase(),"Server://"+resultSplit[4])
        if(show) loading(false)
        return resultSplit[3]
    }
    changeStatus("disconnected")
    if(show) loading(false)
    return "Disconnected"
}

const connectionStatus =  document.getElementById("connection-status")
function changeStatus(status, underText) {
    const textBox = connectionStatus.getElementsByTagName("strong")[0]
    const ssidBox = connectionStatus.getElementsByTagName("strong")[1]
    if(status === "connected"){
        textBox.textContent = "Status: Connected"
        ssidBox.textContent = underText
        connectionStatus.classList.remove("alert-danger","alert-warning")
        connectionStatus.classList.add("alert-success")
        disconnectButton.classList.remove("d-none")
        document.getElementById("config-cards").classList.remove("d-none")
        document.getElementById("connection-section").classList.add("d-none")
    } else if(status === "connecting"){
        textBox.textContent = "Status: Connecting..."
        ssidBox.textContent = underText || ""
        connectionStatus.classList.remove("alert-danger","alert-success")
        connectionStatus.classList.add("alert-warning")
        disconnectButton.classList.add("d-none")
        document.getElementById("config-cards").classList.add("d-none")
        document.getElementById("connection-section").classList.add("d-none")
    } else {
        textBox.textContent = "Status: Disconnected"
        ssidBox.textContent = ""
        connectionStatus.classList.remove("alert-success","alert-warning")
        connectionStatus.classList.add("alert-danger")
        disconnectButton.classList.add("d-none")
        document.getElementById("config-cards").classList.add("d-none")
        document.getElementById("connection-section").classList.remove("d-none")
    }

}

function checkCitylinkLoop(serverIp){
    let attempts = 0;
    const intervalId = setInterval(async () => {
        try {
            const res = await getStatus_iReach(false);
            if(res === "Connected"){
                clearInterval(intervalId);
                loading(false);
            } else {
                attempts++;
                if(attempts > 12){
                    clearInterval(intervalId);
                    loading(false);
                    addCustomAlert("Connection Timeout","Please try again",6000);
                    changeStatus("disconnected");
                }
            }
        } catch (err) {
            console.error("Error checking citylink status", err);
        }
    }, 5000);
}



const showLoadingConnectButton = (show) => {
    document.querySelector('#connect-btn > span').style.display = show ? 'none' : 'inline';
    document.querySelector('#connect-btn > div').style.display = show ? 'inline-block' : 'none';
}
/**
 * Validate and parse the input string.
 * @param {string} input - The input string to validate.
 * @returns {Object|boolean} - Returns a JSON object with key-value pairs if valid, otherwise false.
 */
function validateAndParse(input) {
    // Define regex for the input format
    const regex = /^InRe:([^:]+):([^:]+):(\d+):(\d+):(\d+):(\d+):(\d+)@([a-zA-Z0-9.-]+)$/;
    
    // Test if input matches the format
    const match = input.match(regex);
    if (!match) return false;
  
    // Extract variables from the match
    const [
      ,  // Full match is ignored
      CLIENT_KEY, PASSWORD, DEFAULT_CHISEL_PORT, EXT_PORT1, INT_PORT1, EXT_PORT2, INT_PORT2, SERVER_IP
    ] = match;
  
    // Convert port values to numbers
    const ports = [DEFAULT_CHISEL_PORT, EXT_PORT1, INT_PORT1, EXT_PORT2, INT_PORT2].map(Number);
  
    // Check if all port values are numbers
    if (ports.some(isNaN)) return false;
  
    // Determine if SERVER_IP is a domain, IPv4, or IPv6
    let serverIpType = null;
    if (isIPv4(SERVER_IP)) {
      serverIpType = "IPv4";
    } else if (isIPv6(SERVER_IP)) {
      serverIpType = "IPv6";
    } else if (isDomain(SERVER_IP)) {
      serverIpType = "domain";
    } else {
      return false; // Invalid SERVER_IP format
    }
  
    // Return the JSON object with the extracted values
    return {
      CLIENT_KEY,
      PASSWORD,
      DEFAULT_CHISEL_PORT: ports[0],
      EXT_PORT1: ports[1],
      INT_PORT1: ports[2],
      EXT_PORT2: ports[3],
      INT_PORT2: ports[4],
      SERVER_IP,
      SERVER_IP_TYPE: serverIpType
    };
  }
  
  /**
   * Check if the input is a valid IPv4 address.
   * @param {string} ip - The input to check.
   * @returns {boolean} - True if valid IPv4, false otherwise.
   */
  function isIPv4(ip) {
    const ipv4Regex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipv4Regex.test(ip);
  }
  
  /**
   * Check if the input is a valid IPv6 address.
   * @param {string} ip - The input to check.
   * @returns {boolean} - True if valid IPv6, false otherwise.
   */
  function isIPv6(ip) {
    const ipv6Regex = /^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/;
    return ipv6Regex.test(ip);
  }
  
  /**
   * Check if the input is a valid domain name.
   * @param {string} domain - The input to check.
   * @returns {boolean} - True if valid domain, false otherwise.
   */
  function isDomain(domain) {
    const domainRegex = /^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$/;
    return domainRegex.test(domain);
  }

