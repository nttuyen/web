<!--
  ~ Copyright (C) 2013 eXo Platform SAS.
  ~
  ~ This program is free software; you can redistribute it and/or
  ~ modify it under the terms of the GNU Affero General Public License
  ~ as published by the Free Software Foundation; either version 3
  ~ of the License, or (at your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful,
  ~ but WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  ~ GNU General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with this program; if not, see<http://www.gnu.org/licenses/>.
  -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title></title>

  <%
    String prefix = request.getContextPath();
  %>

  <!--
  <script src="js/jquery-1.7.1.min.js"></script>
  <script src="js/jquery.mousewheel-min.js"></script>
  <script src="js/jquery.terminal-0.7.12.js"></script>
  <script src="js/crash.js"></script>
  <script type="text/javascript" src="js/bootstrap-tab.js"></script>
  <script type="text/javascript" src="js/bootstrap-tooltip.js"></script>
  <script type="text/javascript" src="js/bootstrap-popover.js"></script>
  <script type="text/javascript" src="js/bootstrapx-clickover.js"></script>
  <script type="text/javascript" src="js/bootstrap-alert.js"></script>
  <script type="text/javascript" src="js/bootstrap-modal.js"></script>
  <script type="text/javascript" src="js/codemirror.js"></script>
  <script type="text/javascript" src="js/groovy.js"></script>
  <script type="text/javascript" src="js/twitter.js"></script>
  -->
  <script type="text/javascript" src="<%= prefix %>/js/crash-1.2.js"></script>


  <!--
    <link rel="stylesheet" href="css/codemirror.css">
    <link rel="stylesheet/less" type="text/css" href="less/console-1.2.less"/>
    <script type="text/javascript" src="js/less-1.6.0.min.js"></script>
    <link rel="stylesheet" href="css/jquery.terminal.css"/>
  -->
  <link rel="stylesheet" type="text/css" href="<%= prefix %>/css/console-1.2.css"/>
  <link rel="stylesheet" type="text/css" href="<%= prefix %>/css/crash-1.2.css"/>


  <script type="text/javascript">

    $(document).ready(function() {

      //
/*
      var demo =
              "\n" +
              "\n" +
              "This CRaSH demo provides a few CRaSH features:\n" +

              "Examples (must be created from command templates first):\n" +
              "% dashboard                                                admin dashboard\n" +
              "% thread top                                               show all threads\n" +
              "% thread ls                                                list all threads\n" +
              "% thread dump X                                            dump thread X\n" +
              "% system propget java.version                              display a system property\n" +
              "% system freemem                                           display amount of free memory\n" +

              "\n" +
              "Type 'help' to show the available commands\n";
*/

      // When console tab is shown we give focus to the shell
      $('a[href="#tab0"]').on("shown", function() {
        $("#console").trigger("click");
      });
      // Clear the shell (except the last div that is the prompt box)
      $(".clear-shell").on("click", function(e) {
        // e.preventDefault();
        // $(".jquery-console-inner > div:not(:last)").remove();
      });
      $(".upload-shell").on("click", function(e) {
        e.preventDefault();
        if (!$(this).hasClass("disabled")) {
          // Add scripts to the form before submitting to make them part of the post
          editors.eachEditor(function(editor) {
            var input = $("<input>").attr({
              name : editor.name,
              type : "hidden",
              value : editor.widget.getValue()
            });
            $('#create-gists').append(input);
          });
          document.getElementById('create-gists').submit();
        }
      });
      $(".twitter-shell").on("click", function(e) {
        e.preventDefault();
        if (!$(this).hasClass("disabled")) {
          var text = "I shared JVM shell commands";
          var url = "https://twitter.com/share?via=" + encodeURI("crashub") + "&text=" + encodeURI(text);
          twitter(url);
        }
      });
      $(".gplus-shell").on("click", function(e) {
        e.preventDefault();
        if (!$(this).hasClass("disabled")) {
          var url = "http://plus.google.com/share?url=" + encodeURI(window.location);
          twitter(url);
        }
      });

      // State
      var editors = {
        count: 0,
        state: {},
        addEditor: function(id, editor) {
          this.state[id] = editor;
          this.count++;
        },
        removeEditor: function(id) {
          var editor = this.state[id];
          delete this.state[id];
          this.count--;
          return editor;
        },
        getEditor: function(id) {
          return this.state[id];
        },
        getEditorByName: function(name) {
          var found;
          this.eachEditor(function(editor) {
            if (editor.name == name) {
              found = editor;
            }
          });
          return found;
        },
        eachEditor: function(callback) {
          for (var k in this.state) {
            if (this.state.hasOwnProperty(k)) {
              callback(this.state[k]);
            }
          }
        }
      };
      var tabSeq = 1; // 0 == console
      var current = null; // Current tab

      // Script functions
      var addScript = function(name, script) {
        var tabId = "tab" + tabSeq++;
        var tab = $('<li><a href="#' + tabId + '">' + name + '</a></li>');
        var pane = $('<div id="' + tabId + '" class="tab-pane">' +
          '<div class="btn-toolbar"><div class="btn-group btn-group-vertical" style="float:right">' +
          '<a class="btn remove-command" href="#" title="Remove this command"><i class="icon-remove-circle"></i></a>' +
          '</div></div>' +
          '<form><textarea rows="16"" cols="80"></textarea>' +
          '</form>' +
          '</div>');
        $("#tab-content").append(pane);
        $("#nav-tabs li:last").before(tab);
        var textarea = pane.find("textarea").each(function() {
          var widget = CodeMirror.fromTextArea(this, {
            mode: "groovy",
            lineNumbers: true,
            lineWrapping: false,
            tabindex: 2
          });
          var editor = {
            name: name,
             widget: widget,
             stale: false
          };
          widget.setValue(script);
          widget.on("change", function() {
            editor.stale = true;
          });
          editors.addEditor(tabId, editor);
        });
        return tab;
      };

      // Tab navigation
      $('#nav-tabs').on('click', 'a[href*="#tab"]', function(e) {
        e.preventDefault();
        var link = this;
        var show = function() {
          $(link).tab("show");
        };
        if (current != null) {
          var id = $(current).attr("href").substring(1);
          if (id == 'tab0') {
            show();
          } else {
            var editor = editors.getEditor(id);
            var tab = this;
            if (editor.stale) {
              $.ajax({
                async: false,
                type: "POST",
                url: "<%= prefix %>/script",
                data: {
                  "name": editor.name,
                  "script": editor.widget.getValue()
                },
                statusCode: {
                  200: function() {
                    editor.stale = false;
                    $(".upload-shell").removeClass("disabled");
                    $(".twitter-shell").addClass("disabled");
                    $(".gplus-shell").addClass("disabled");
                    show();
                  },
                  400: function(xhr, status, response) {
                    // We should ensure that the response content type is json
                    var json = $.parseJSON(xhr.responseText);
                    $("#compilation-error-dialog-body").text(json.message);
                    $('#compilation-error-dialog').modal("show")
                  }
                }
              });
            } else {
              show();
            }
          }
        } else {
          show();
        }
      });

      // Refresh editor when tab is shown
      $('#nav-tabs').on('shown', 'a[href*="#tab"]', function (e) {
        var id = $(e.target).attr("href").substring(1);
        var editor = editors.getEditor(id);
        if (editor != null) {
          editor.widget.refresh();
        }
        current = e.target;
      });

      // Remove script
      $('body').on("click", "a.remove-command", function(e) {
        e.preventDefault();
        var pane = $(this).closest(".tab-pane");
        var id = pane.attr("id");
        var editor = editors.removeEditor(id);
        current = null;
        $('a[href="#tab0"]').tab('show');
        pane.remove();
        $('a[href="#' + id + '"]').remove();
        $.ajax({
          type: "DELETE",
          url: "<%= prefix %>/script?" + $.param({"name":editor.name})
        });
        $(".upload-shell").addClass("disabled");
        $(".twitter-shell").addClass("disabled");
        $(".gplus-shell").addClass("disabled");
        var count = 0;
        if (editors.count > 0) {
          $(".upload-shell").removeClass("disabled");
        }
      });

      // Add command pop over
      $("#add-command").clickover({
          onShown: function() {
            $("#command-name").focus();
            crash.pause();
            console.debug(document.activeElement)
        }
      });
      $("body").on("keyup", "#command-name", function(e) {
        if (e.keyCode == 13) {
          var name = $(this).val();
          var template = $("#command-template").val();
          var script = "public class " + name + " {\n  @Command\n  public void main() {\n    out.println('hello');\n  }\n}";
          $("#template-" + template).each(function() {
            script = $(this).text();
            script = script.replace("{{name}}", name); // Replace {{name}} by name
          });
          if (name == null || name.length == 0) {
            $('#invalid-name-dialog').modal("show")
          } else if (editors.getEditorByName(name)) {
            $('#duplicate-name-dialog').modal("show")
          } else {
            $.ajax({
              async: false,
              type: "POST",
              url: "<%= prefix %>/script",
              data: {
                name: name,
                script: script
              },
              statusCode: {
                200: function() {
                  var tab = addScript(name, script);
                  var id = tab.find("a").tab("show").attr("href");
                  // Hack for dismissing bootstrapx-clickover
                  var event = jQuery.Event("keyup.clickery");
                  event.which = 27;
                  event.keyCode = 27;
                  $(".upload-shell").removeClass("disabled");
                  $(".twitter-shell").addClass("disabled");
                  $(".gplus-shell").addClass("disabled");
                  $('#add-command').trigger(event);
                  crash.resume()
                },
                400: function(xhr, status, response) {
                  // We should ensure that the response content type is json
                  var json = $.parseJSON(xhr.responseText);
                  $("#compilation-error-dialog-body").text(json.message);
                  $('#compilation-error-dialog').modal("show")
                }
              }
            });
          }
        }
      });

      // Are we showing a gist ?
      var match = window.location.pathname.match(/\/gists\/([0-9]+)/);
      if (match) {
        $('.github-shell').attr("href", "https://gist.github.com/" + match[1]).css("display", "block");
      }

      // Download scripts from session
      $.ajax({
        url: "<%= prefix %>/scripts",
        success: function(data) {
          for (var name in data) {
            if (data.hasOwnProperty(name)) {
              addScript(name, data[name]);
            }
            if (!match && editors.count > 0) {
              $(".upload-shell").removeClass("disabled");
              $(".twitter-shell").addClass("disabled");
              $(".gplus-shell").addClass("disabled");
            }
          }
        }
      });

      //
      var search = window.location.search;
      if (search) {
        var re = /\?(?:[^&]+&)?exec=([^($|&)]+)/;
        match = re.exec(search);
        if (match) {
          var exec = decodeURI(match[1]);
          controller.promptText(exec);

          // REAL NASTY HACK... but that works... should find something really much better
          // because it is way more than border line
          var press = jQuery.Event("keypress");
          press.keyCode = 13;
          controller.typer.data("events").keydown[0].handler(press);
        }
      }
    });
  </script>

  <script type="text/javascript">

      //
      $(function() {
          // Create web socket url
          var protocol;
          if (window.location.protocol == 'http:') {
              protocol = 'ws';
          } else {
              protocol = 'wss';
          }
          var url = protocol + '://' + window.location.host + "<%= prefix %>" + '/crash';

          // Set top level crash on purpose
          crash = new CRaSH($('#console'), 960, 600);
          crash.connect(url);
      });

  </script>


  <!-- Google Analytics -->
  <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-18968252-4']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();

  </script>
</head>
<body>

<div class="navbar navbar-fixed-top">
  <div class="navbar-inner">
    <div class="container">
      <ul id="tabs" class="nav">
        <li><a href="http://www.crashub.org" target="blank">Crashub</a></li>
        <li><a href="http://www.crashub.org/beta/reference.html" target="blank">Documentation</a></li>
      </ul>
    </div>
  </div>
</div>

<div class="container">
  <div class="row">
    <div class="span12">
      <p style="text-align: center">Sponsored by <a href="http://www.exoplatform.com" target="blank">eXo Platform</a>,
          follow our <a href="http://blog.exoplatform.com" target="blank">developer's blog</a>!</p>
    </div>
  </div>
  <div class="row">
    <div class="span12">
      <div class="tabbable tabs-right">
        <ul id="nav-tabs" class="nav nav-tabs">
          <li class="active"><a href="#tab0">Console</a></li>
          <li style="text-align:center">
            <a
              id="add-command"
              href="#"
              data-placement="bottom"
              data-html="true"
              data-trigger="manual"
              data-content="<div><input id='command-name' type='text'/></div><div><select id='command-template'><option>hello</option><option>date</option></div>"
              data-original-title="Add command"><i class="icon-plus-sign-alt"></i></a>
          </li>
        </ul>
        <div id="tab-content" class="tab-content">
          <div class="tab-pane active" id="tab0">
              <div class="btn-toolbar">
              <div class="btn-group btn-group-vertical" style="float:right">
                <a class="btn upload-shell disabled" href="#" title="Upload your commands"><i class="icon-cloud-upload"></i></a>
                <a class="btn twitter-shell" href="#" title="Share on twitter"><i class="icon-twitter"></i></a>
                <a class="btn gplus-shell" href="#" title="Share on Google+"><i class="icon-google-plus"></i></a>
                <a style="display: none" class="btn github-shell" href="#" title="View gist" target="_blank"><i class="icon-github"></i></a>
                <a class="btn clear-shell" href="#" title="Clear the shell"><i class="icon-trash"></i></a>
              </div>
            </div>
            <div id="console"></div>
            <form id="create-gists" action="gists" method="post"></form>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Used to determine font metric -->
<div id="metric" class="console" style="position: absolute;visibility: hidden;height: auto; width: auto">
  <div class="jquery-console-message">A</div>
</div>

<div id="compilation-error-dialog" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-body">
    <div class="alert alert-error">
      <strong>Compilation error</strong>
    </div>
    <pre id="compilation-error-dialog-body"></pre>
  </div>
</div>

<div id="invalid-name-dialog" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-body">
    <div class="alert alert-error">
      <strong>Invalid name</strong>
    </div>
  </div>
</div>

<div id="duplicate-name-dialog" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-body">
        <div class="alert alert-error">
            <strong>Command already exist</strong>
        </div>
    </div>
</div>

<!-- The command templates -->
<pre id="template-hello" style="display:none">
// The simplest command
return "hello world";
</pre>
<pre id="template-date" style="display:none">
// Class based commands using annotations
class {{name}} {
  @Usage("show the current time")
  @Command
  Object main(@Usage("the time format") @Option(names=["f","format"]) String format) {
    if (format == null)
      format = "EEE MMM d HH:mm:ss z yyyy";
    def date = new Date();
    return date.format(format);
  }
}
</pre>

</body>
</html>
