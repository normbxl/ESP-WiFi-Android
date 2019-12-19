import hypermedia.net.*;
import java.lang.*;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.EnumMap;
import java.util.Collections;

import android.net.*;
import android.net.wifi.WifiManager;
import android.content.Context;
import android.app.Activity;
import android.net.nsd.NsdManager;
import android.net.nsd.NsdManager.*;
import android.net.nsd.NsdServiceInfo;
/**
 4 Device-Ports (S1, S2, M1, M2 and ADC),
 Possible config: for S1/S2:
 - No Use
 - Digital
 - Analog (PWM)
 - Servo
 
 Device-Port M1/M":
 - MOTOR
 . Since the pins are directly connected to the H-BRidge driver
 Other configs are useless
 
 Device-Port ADC:
 - Read-only
 */
public enum PortType {
  NOUSE, 
  DIGIT, 
  SERVO, 
  ANLOG, 
  MOTOR
}

public enum DevicePort {
  S1, S2, M1, M2, ADC
}

class DevicePortConfig {
  public PortType type=PortType.NOUSE;
  public int value=0;
  public DevicePortConfig(PortType type, int value) {
    this.type=type;
    this.value=value;
  }

  public DevicePortConfig(PortType type) {
    this(type, 0);
  }

  public DevicePortConfig(String typeString, int value) {
    for (PortType type : PortType.values()) {
      if (type.name() == typeString) {
        this.type=type;
        break;
      }
    }
    this.value=value;
  }
}

public class DeviceLink {
  private final int UDP_PORT = 4210;
  private UDP udp;
  private String ip;
  private Semaphore sema;
  private String lastJsonStr="";
  private JSONObject recJson=null;

  private Context context;
  private String serviceName;
  public final String SERVICE_TYPE="_wifi-rc._udp.";

  private DiscoveryListener discoveryListener;
  private NsdManager nsdManager;
  private ResolveListener resolveListener;
  private RegistrationListener registrationListener;

  public EnumMap<DevicePort, DevicePortConfig> deviceConfig = 
    new EnumMap<DevicePort, DevicePortConfig>(DevicePort.class);

  public EnumMap<DevicePort, Integer> portValues = 
    new EnumMap<DevicePort, Integer>(DevicePort.class);

  // called by UDP on receiving data
  public void receive(byte[] data) {
    String str = new String(data);
    if (str.indexOf('{') != -1) {
      recJson = JSONObject.parse(str);
    }
    if (sema.availablePermits()==0) {
      sema.release();
    }
  }

  public void initializeRegistrationListener() {
    registrationListener = new NsdManager.RegistrationListener() {

      @Override
        public void onServiceRegistered(NsdServiceInfo NsdServiceInfo) {
        // Save the service name. Android may have changed it in order to
        // resolve a conflict, so update the name you initially requested
        // with the name Android actually used.
        serviceName = NsdServiceInfo.getServiceName();
      }

      @Override
        public void onRegistrationFailed(NsdServiceInfo serviceInfo, int errorCode) {
        // Registration failed! Put debugging code here to determine why.
      }

      @Override
        public void onServiceUnregistered(NsdServiceInfo arg0) {
        // Service has been unregistered. This only happens when you call
        // NsdManager.unregisterService() and pass in this listener.
      }

      @Override
        public void onUnregistrationFailed(NsdServiceInfo serviceInfo, int errorCode) {
        // Unregistration failed. Put debugging code here to determine why.
      }
    };
  }

  public void initializeResolveListener() {
    resolveListener = new NsdManager.ResolveListener() {

      @Override
        public void onResolveFailed(NsdServiceInfo serviceInfo, int errorCode) {
        // Called when the resolve fails. Use the error code to debug.
        println("resolve failed");
      }

      @Override
        public void onServiceResolved(NsdServiceInfo serviceInfo) {
        println("Resolve Succeeded. " + serviceInfo);

        connect(serviceInfo.getHost().getHostAddress());
      }
    };
  }

  public void initializeDiscoveryListener() {

    // Instantiate a new DiscoveryListener
    discoveryListener = new DiscoveryListener() {
      // Called as soon as service discovery begins.
      @Override
        public void onDiscoveryStarted(String regType) {
        println("Service discovery started");
      }

      public void onServiceFound(NsdServiceInfo service) {
        // A service was found! Do something with it.
        println("Service discovery success" + service);
        println("Service type: "+service.getServiceType().toString());
        println("Service name: "+service.getServiceName());
        if (!service.getServiceType().equals(SERVICE_TYPE)) {
          // Service type is the string containing the protocol and
          // transport layer for this service.
          println("Unknown Service Type: " + service.getServiceType());
        } else if (service.getServiceName().equals(serviceName)) {
          // The name of the service tells the user what they'd be
          // connecting to. It could be "Bob's Chat App".
          println("Same machine: " + serviceName);
        } else if (service.getServiceName().contains("wifi-rc") ) {
          nsdManager.resolveService(service, resolveListener);
        }
      }

      @Override
        public void onServiceLost(NsdServiceInfo service) {
        // When the network service is no longer available.
        // Internal bookkeeping code goes here.
      }

      @Override
        public void onDiscoveryStopped(String serviceType) {
      }

      @Override
        public void onStartDiscoveryFailed(String serviceType, int errorCode) {
        nsdManager.stopServiceDiscovery(this);
      }

      @Override
        public void onStopDiscoveryFailed(String serviceType, int errorCode) {
        nsdManager.stopServiceDiscovery(this);
      }
    };
  }

  public void registerService(int port) {
    NsdServiceInfo serviceInfo = new NsdServiceInfo();
    serviceInfo.setServiceName("wifi-rc");
    serviceInfo.setServiceType("_wifi-rc._udp.");
    serviceInfo.setPort(port);

    nsdManager = (NsdManager)context.getSystemService(Context.NSD_SERVICE);

    nsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener);
  }

  public String GetGatewayIp() {
    try {
      WifiManager wifiMan = (WifiManager)getActivity().getSystemService(Context.WIFI_SERVICE);
      DhcpInfo d = wifiMan.getDhcpInfo();
      return String.valueOf(d.gateway);
    }
    catch(Exception ex) {
      return "";
    }
  }

  // callback on timeout by UDP
  public void timeout() {
    recJson = null;
    sema.release();
  }

  public DeviceLink(Context context) {
    this.context = context;
    initializeRegistrationListener();
    initializeResolveListener();

    registerService(4210);
    initializeDiscoveryListener();

    nsdManager.discoverServices("_wifi-rc._udp.", NsdManager.PROTOCOL_DNS_SD, discoveryListener);

    // one semaphore slot
    sema = new Semaphore(1);
  }

  public boolean isConnected() {
    return udp==null ? false : !udp.isClosed();
  }

  public void connect(String ip) {
    this.ip = ip;
    udp = new UDP(this);
    // udp.log(true);
    udp.listen(true);
    println("Connecting to "+ip);
  }

  public String getRemoteIp() {
    return ip;
  }

  public int getPortValue(DevicePort devPort) {
    if (deviceConfig.containsKey(devPort)) {
      return deviceConfig.get(devPort).value;
    }
    throw new IndexOutOfBoundsException();
  }

  public boolean requestDeviceConfiguration() {
    JSONObject json=new JSONObject();
    boolean result=false;

    json.setString("cmd", "get");
    json.setString("type", "config");

    //System.out.print("JSON request to send: "+json.toString());

    udp.send(json.toString(), ip, UDP_PORT);
    // wait 2000 ms for response
    try {
      // semaphore is released in receive method, 
      // which also fills the recJson object
      if (sema.tryAcquire(2000, TimeUnit.MILLISECONDS)) {
        if (recJson != null) {
          // parse recJson
          // go over device ports and read config
          // TODO: what about the ADC? Implement!
          result=true;
          for (DevicePort devPort : DevicePort.values()) {
            JSONObject jObj = recJson.getJSONObject(devPort.name());
            if (jObj != null) {
              try {
                deviceConfig.put(devPort, new DevicePortConfig(
                  jObj.getString("type"), 
                  jObj.getInt("value")));
              }
              catch(Exception ex) {
                System.out.print("Exception reading config: "+ex.getMessage());
                result=false;
              }
            }
          }
        }
      } else {
        System.out.println("Send semaphore timed out");
        result=false;
      }
    }
    catch (InterruptedException ex) {
      result=false;
    }
    return result;
  }

  public void setOutput(DevicePort devPort, Integer value) {
    portValues.put(devPort, value);
  }

  public void sendControlUpdate() {
    JSONObject jObj=new JSONObject();
    jObj.setString("type", "control");
    jObj.setString("cmd", "set");
    for (DevicePort port : portValues.keySet()) {
      jObj.setInt(port.toString(), portValues.get(port));
    }
    if (lastJsonStr == jObj.toString()) {
      return;
    }
    udp.send(jObj.toString(), ip, UDP_PORT);
    lastJsonStr = jObj.toString();
  }

  public void close() {
    nsdManager.unregisterService(registrationListener);
    nsdManager.stopServiceDiscovery(discoveryListener);
    udp.close();
  }
}
