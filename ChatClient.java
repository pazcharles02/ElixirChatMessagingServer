import java.net.*;
import java.io.*;

class ChatClient {
  public static void main(String... args) throws IOException {
     Socket s;
     if (args.length > 1) {
       s = new Socket(args[0], Integer.parseInt(args[1]));
     } else if (args.length == 1) {
       s = new Socket(args[0], 6666);
     } else {
       s = new Socket("127.0.0.1", 6666);
     }

     try {
       var in = new BufferedReader(new InputStreamReader(s.getInputStream()));
       var out = new PrintWriter(new OutputStreamWriter(s.getOutputStream()), true); // true = autoflush
       var stdin = new BufferedReader(new InputStreamReader(System.in));
     
       String line;

       class ReplyThread extends Thread {
         String reply;
         public void run() {
           while (true) {
             try {
               if ((reply = in.readLine()) == null) break;
               System.out.printf("%s\n> ", reply);
             } catch (IOException e) {
               System.out.println("Connection with socket terminated, program terminating.");
               break;
             }
           }
         }
       }
       while (true) {
         System.out.print("> ");

         if ((line = stdin.readLine()) == null) {
           System.out.println("End-of-file key inputted, program terminating");
           break;
         }

         out.println(line);
         (new ReplyThread()).start();
         if ((in.readLine()) == null) break;
       }
     } catch (SocketException e) {
       s.close();
    }
     finally {
       s.close();
     }
  }
}
