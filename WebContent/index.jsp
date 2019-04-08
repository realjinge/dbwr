<%@page trimDirectiveWhitespaces="true" %>
<%@page import="dbwr.WebDisplayRepresentation"%>
<!DOCTYPE html>
<html>

<head>
<meta charset="UTF-8">
<title>Display Builder Web Runtime</title>
<link rel="stylesheet" type="text/css" href="css/widgets.css">
<script type="text/javascript" src="../pvws/js/jquery-3.3.1.js"></script>
</head>

<body>

<h1>Display Builder Web Runtime</h1>

<h3>Example</h3>

<p>Enter a 'file:' or 'http:' URL for a *.bob or *.opi display:<p>

<form id="open_form">
    <table>
    <tr>
      <td>Display:</td>
      <td><input type="text" name="display" style="width: 95%;"></td>
      <td></td>
    </tr>
    <tr>
      <td></td>
      <td>     
        <select name="options" style="width: 95%;">
		<% for (String dsp : WebDisplayRepresentation.display_options)
		        out.println("<option>" + dsp + "</option>");
		%>
        </select>
      </td>
      <td></td>
    </tr>
    <tr>
      <td>Macros:</td>
      <td><input type="text" name="macros" style="width: 95%;"></td>
      <td><input type="button" value="Open"></td>
    </tr>
    </table>
</form>

<h4>Client URLs</h4>

<p>Display a file that's in the file system of the Tomcat host:</p>
<pre class="example_url">
view.jsp?display=file:/Path/to/Display+Builder/01_main.bob
</pre>

<p>Serve file that's fetched via http: or https:</p>
<pre class="example_url">
view.jsp?display=https%3A//some_host/opi/file.opi
</pre>


<h4>Macros</h4>

<p>When manually entering a URL, you can use the syntax
<code>$(NAME)=Some Value&amp;$(OTHER)=Other Value</code> as in
<pre class="example_url">
view.jsp?display=https://some_host/opi/file.opi&amp;$(S)=06&amp;$(S1)=06
</pre>

<p>That simplified mechanism, however, is limited when you try to
pass values which contain '=' or '&amp;'.
</p>

<p>A more robust mechanism passes macros as a <code>macros=JSON map</code>,
for example <code>{"S"="06", "S1"="06"}</code>,
but note that the map needs to be URL encoded, for example using JavaScript
<code>encodeURIComponent('{"NAME"="Value"}')</code>, resulting in
</p>

<pre class="example_url">
view.jsp?display=https://some_host/opi/file.opi&amp;macros=%7B%22S%22%3A%2206%22%2C%22S1%22%3A%2206%22%7D
</pre>


<h4>Cache</h4>

<p>Page requests are cached, and this URL returns cache info:</p>
<pre class="example_url">
cache
</pre>

<input type="button" value="Cache Info" onclick="query_cache()">
<input type="button" value="Clear Cache" onclick="clear_cache()">

<p></p>

<div id="info"></div>

<script type="text/javascript">

function format_date(date)
{
    return date.toLocaleString("en-US", { hour12: false });
}

function query_cache()
{
    let info = jQuery("#info");
    info.html("Fetching cache info...");
    
    jQuery.ajax(
    {
        url: "cache",
        method: "GET",
        dataType: "json",
        success: data =>
        {
            if (! data  ||  !data.displays  || data.displays.length <= 0)
            {
                info.html("Cache is empty");
                return;
            }
            // Build table: Header
            info.html("");
            let table = jQuery("<table>").css("table-layout", "fixed")
                                         .css("word-wrap", "break-word");
            table.append($("<tr>").append($("<th>").css("width", "40%").text("Display"))
                                  .append($("<th>").css("width", "15%").text("Macros"))
                                  .append($("<th>").css("width", "10%").text("Created"))
                                  .append($("<th>").css("width", "10%").text("Last Access"))
                                  .append($("<th>").css("width", "10%").text("Size"))
                                  .append($("<th>").css("width", "5%").text("Calls"))
                                  .append($("<th>").css("width", "10%").text("Time")) );
            // .. Rows
            let size = 0, calls = 0, ms = 0;
            for (let display of data.displays)
            {
                size += display.size;
                calls += display.calls;
                ms += display.ms;
                table.append($("<tr>").append($("<td>").text(display.display))
                                      .append($("<td>").text(JSON.stringify(display.macros)))
                                      .append($("<td>").text(format_date(new Date(display.created))))
                                      .append($("<td>").text(format_date(new Date(display.stamp))))
                                      .append($("<td>").css("text-align", "right").text( (display.size / 1024.0).toFixed(1) + " kB" ))
                                      .append($("<td>").css("text-align", "right").text(display.calls))
                                      .append($("<td>").css("text-align", "right").text( (display.ms / 1000.0).toFixed(3) + " ms")) );
            }
            table.append($("<tr>").append($("<td>"))
   			                      .append($("<td>"))
                                  .append($("<td>"))
				                  .append($("<td>").html("<b>Total:</b>"))
				                  .append($("<td>").css("text-align", "right").text( (size / 1024.0).toFixed(1) + " kB" ))
				                  .append($("<td>").css("text-align", "right").text(calls))
				                  .append($("<td>").css("text-align", "right").text( (ms / 1000.0).toFixed(3) + " ms")) );
            info.append(table);
            // Scroll to 'bottom' to show table
            window.scrollTo(0, 100000);
        },
        error: (xhr, status, error) => info.html("No Info: " + status),        
    });
}

function clear_cache()
{
    let info = jQuery("#info");
    info.html("Clearing cache ..");
    
    jQuery.ajax(
    {
        url: "cache",
        method: "DELETE",
        success: data =>
        {
            // Clear
            info.html("Cache cleared");
            query_cache();
        },
        error: (xhr, status, error) => info.html("Cache Clear Error: " + status),        
    });
}


jQuery(() =>
{
    // Add actual http://.. location to the example URLs
    let root = window.location.origin + window.location.pathname;
    jQuery(".example_url").each( (index, example) =>
    {
        let ex = jQuery(example);
        let url = ex.html();
        ex.html(root + url);
    });
    
    // Populate input with the first option
    jQuery("#open_form input[name=display]").val( jQuery("#open_form select option")[0].value );

    // Update input when another option is selected
    let options = jQuery("#open_form select");
    options.change(() => jQuery("#open_form input[name=display]").val(options.val()));
    
    jQuery("#open_form input[name=macros]").val("$(S)=Value One&$(N)=1");
    jQuery("#open_form input[type=button]").click(() =>
    {
        let display = jQuery("#open_form input[name=display]").val();
        let macros = jQuery("#open_form input[name=macros]").val();
        
        let new_link = root + "view.jsp?display=" + display;
        
        if (macros)
        {   // Parse $(NAME)=VALUE&$(NAME)=VALUE into NAME, VALUE
	        let map = {}, i = 0, items = macros.split("&");
	        while (i < items.length)
	        {
	            let name_value = items[i].split('=');
	            let name = name_value[0];
	            // Remove $( .. ) from NAME
	            name = name.replace("$(", "");
	            if (name.endsWith(")"))
	                name = name.substr(0, name.length-1)
	            map[name] = name_value[1];
	            i += 1;
	        }
	        macros = JSON.stringify(map)
	        new_link = new_link + "&macros=" + encodeURI(macros);
        }
        
        // if (confirm(new_link))
        window.location.href = new_link;
    });
});
</script>
</body>

</html>