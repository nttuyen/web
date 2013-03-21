package org.crsh.web;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.ws.rs.core.MediaType;
import java.io.IOException;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** @author <a href="mailto:julien.viet@exoplatform.com">Julien Viet</a> */
@WebServlet(urlPatterns = "/gists/*")
public class GistsServlet extends HttpServlet {

  /** . */
  private static final Pattern GROOVY = Pattern.compile("(\\p{Alpha}\\p{Alnum}*)(?:\\.groovy)?", Pattern.CASE_INSENSITIVE);

  @Override
  protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

    String pathInfo = req.getPathInfo();
    if (pathInfo == null || pathInfo.length() < 2) {
      resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "No gist id provided");
    } else {
      // Remove /
      String id = pathInfo.substring(1);

      // Get gist
      Client c = Client.create();
      WebResource r = c.resource("https://api.github.com/gists/" + id);
      ClientResponse response = r.accept(MediaType.APPLICATION_JSON_TYPE).get(ClientResponse.class);
      String entity = response.getEntity(String.class);

      //
      int status = response.getStatus();
      if (status >= 200 && status <= 299) {
        JsonObject object= (JsonObject)new JsonParser().parse(entity);
        LifeCycle lf = LifeCycle.getLifeCycle(getServletContext());
        JsonObject files = object.getAsJsonObject("files");
        for (Map.Entry<String, JsonElement> entry : files.entrySet()) {
          Matcher m = GROOVY.matcher(entry.getKey());
          if (m.matches()) {
            String name = m.group(1);
            JsonObject file = (JsonObject)entry.getValue();
            String content = file.get("content").getAsString();
            lf.getCommands().setScript(name, content);
          }
        }

        // Display index
        getServletContext().getRequestDispatcher("/index.html").include(req, resp);
      } else if (status == 404) {
        resp.sendError(HttpServletResponse.SC_NOT_FOUND, "No such gist " + id);
      } else {
        resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not retriev gist " + id + " status=" + status + " body=" + entity);
      }
    }
  }

  @Override
  protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

    //
    String pathInfo = req.getPathInfo();
    if (pathInfo != null && pathInfo.length() > 0) {
      resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "No gist id must be provided");
    } else {

      // Build body
      JsonObject body = new JsonObject();
      body.addProperty("description", "the description for this gist");
      body.addProperty("public", true);
      JsonObject files = new JsonObject();
      LifeCycle lf = LifeCycle.getLifeCycle(getServletContext());
      SimpleFS commands = lf.getCommands();
      for (String name : commands.list()) {
        String script = commands.getScript(name);
        JsonObject file = new JsonObject();
        file.addProperty("content", script);
        files.add(name + ".groovy", file);
      }
      body.add("files", files);

      // Perform request
      Client c = Client.create();
      WebResource r = c.resource("https://api.github.com/gists");
      ClientResponse response = r.accept(MediaType.APPLICATION_JSON_TYPE).type(MediaType.APPLICATION_JSON_TYPE).post(ClientResponse.class, body.toString());
      String entity = response.getEntity(String.class);

      //
      int status = response.getStatus();
      if (status >= 200 && status <= 299) {
        JsonObject object= (JsonObject)new JsonParser().parse(entity);
        String id = object.getAsJsonPrimitive("id").getAsString();
        resp.sendRedirect("/gists/" + id);
      } else {
        resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not create gist status =" + status + " entity = " + entity);
      }
    }
  }
}