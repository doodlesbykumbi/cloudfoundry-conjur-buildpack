package hello.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
class HelloController {

  @RequestMapping("/")
  ResponseEntity<String> getPet() {
    String body = 
        "<h1>Visit us @ www.conjur.org!</h1>\n" +
        "<h3>Space-wide Secrets</h3>\n" +
        "<p>Database Username: " + System.getenv("SPACE_USERNAME") + "</p>\n" +
        "<p>Database Password: " + System.getenv("SPACE_PASSWORD") + "</p>";

      return ResponseEntity.ok().body(body);
  }
}