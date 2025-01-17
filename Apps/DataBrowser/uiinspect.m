function hFig = uiinspect(obj, fig)
% uiinspect Inspect an object handle (Java/COM/HG) and display its methods/props/callbacks in a unified window
%
% Syntax:
%    hFig = uiinspect(obj, hFig)    % hFig input argument is optional
%
% Description:
%    UIINSPECT(OBJ) inspects an object handle (e.g., Java, COM, Handle
%    Graphics, Matlab class etc.) and displays inspection results in a
%    Matlab figure window with all the relevant object methods (as can be
%    displayed via Matlab's methodsview function), properties (as can be
%    displayed via Matlab's inspect function), static fields and callbacks.
%    UIINSPECT also displays properties that are not normally displayed
%    with Matlab's inspect function. Property meta-data such as type,
%    accessibility, visibility and default value are also displayed (where
%    available).
%
%    If the inspected object is an HG handle, then a component tree is
%    displayed instead of the methods pane (see attached animated screenshot).
%
%    Unlike Matlab's inspect function, multiple UIINSPECT windows can be
%    opened simultaneously.
%
%    Object properties and callbacks may be modified interactively within
%    the UIINSPECT window.
%
%    UIINSPECT(OBJ) reuses an already-displayed UIINSPECT window if its
%    title is the same (i.e., same object or class); otherwise a new window
%    is created. UIINPECT(OBJ,hFIG) forces using the specified hFig window
%    handle, even if another window would otherwise have been reused/created.
%
%    hFig = UIINSPECT(...) returns a handle to the UIINSPECT figure window.
%    UIINSPECT creates a regular Matlab figure window which may be accessed
%    via this hFig handle (unlike Matlab's methodsview function which opens
%    a Java frame that is not easily accessible from Matlab).
%
% Examples:
%    hFig = uiinspect(0);              % root (desktop)
%    hFig = uiinspect(handle(0));      % root handle
%    hFig = uiinspect(gcf);            % current figure
%    uiinspect(get(gcf,'JavaFrame'));  % current figure's Java Frame
%    uiinspect(classhandle(handle(gcf)));         % a schema.class object
%    uiinspect(findprop(handle(gcf),'MenuBar'));  % a schema.prop object
%    uiinspect('java.lang.String');               % a Java class name
%    uiinspect(java.lang.String('yes'));          % a Java object
%    uiinspect(actxserver('Excel.Application'));  % a COM object
%    uiinspect(Employee)                          % a Matlab class object
%    uiinspect(?handle)                           % a Matlab metaclass object
%    uiinspect('meta.class')                      % a Matlab class name
%
% Known issues/limitations:
%    - Fix: some fields generate a Java Exception, or a Matlab warning
%    - other future enhancements may be found in the TODO list below
%
% Warning:
%    This code heavily relies on undocumented and unsupported Matlab functionality.
%    It works on Matlab 7+, but use at your own risk!
%
% Bugs and suggestions:
%    Please send to Yair Altman (altmany at gmail dot com)
%
% Change log:
%    2010-01-16: Fixed a few bugs in properties meta-info of Matlab classes
%    2009-10-23: Added CaretPositionChanged & InputMethodTextChanged to list of standard callbacks; minor fix to requesting focus of Java handles; minor fix to version-check display
%    2009-05-22: Added support for Matlab classes (helped by Darik Gamble); improved display for classname input
%    2009-05-20: Fixed methods info gathering for some handles
%    2009-05-19: Improved information display for HG handles; added HG-handle screenshot to animated gif (added to COM, Java screenshots); enabled reuse of uiinspect window
%    2009-05-04: Fixed setting callbacks on non-handle('CallbackProperties')ed Java objects; fixed input param edge-case; hyperlinked the className to Sun's Javadocs where relevant; auto-checked newer version; removed main menu
%    2009-04-16: Fixed occasional endless loop upon callback update error
%    2009-04-01: Fixed case of no methods (e.g., uimenus); fixed superclass/interfaces of classname input; auto-hide callbacks pane if no CBs are available
%    2009-03-30: Added Extra method details checkbox (default=off); auto-hide inspectable checkbox if irrelevant; auto-sort methods by args list; hyperlinked classes; fixed title for classname inputs
%    2009-03-14: Fixed string property value displayed; fixed display of Java classes added to the dynamic classpath; fixed display of classname static fields value; updated list of standard callbacks
%    2009-03-05: Fixed single property edge-case; fixed prop name case sensitivity problem; fixed properties tooltip; accept class names; added display of class interfaces & static fields
%    2008-01-25: Fixes for many edge-cases
%    2007-12-08: First version posted on <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadAuthor.do?objectType=author&mfx=1&objectId=1096533#">MathWorks File Exchange</a>
%
% See also:
%    ishandle, iscom, inspect, methodsview, FindJObj (on the File Exchange)

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.9 $  $Date: 2009/10/23 16:10:38 $

  try
      % Arg check
      error(nargchk(1,2,nargin));
      try
          mc = getMetaClass(obj);
      catch
          mc = [];
      end
      if ~ischar(obj) && (isempty(obj) || (~ishandle(obj) && isempty(mc)))
          myError('YMA:uiinspect:notAHandle','Input to uiinspect must be a valid object as defined by ISHANDLE');
      elseif ~ischar(obj) && (numel(obj) ~= 1)
          myError('YMA:uiinspect:notASingleton','Input to uiinspect must be a single object handle');
      elseif isnumeric(obj) && ishandle(obj)
          obj = handle(obj);
      end
      if nargin < 2
          fig = [];
      elseif ~ishandle(fig) || ~ishghandle(fig) || ~isa(handle(fig),'figure')
          myError('YMA:uiinspect:notAFigure','Second input to uiinspect must be a valid figure handle');
      end

      % Get object data
      objMethods   = getObjMethods(obj);
      objProps     = getObjProps(obj);
      objCallbacks = getObjCallbacks(obj);
      objChildren  = getObjChildren(obj);
      
      % Display object data
      fig = displayObj(obj, objMethods, objProps, objCallbacks, objChildren, inputname(1), fig);
      if nargout,  hFig = fig;  end
% {
  % Error handling
  catch
      v = version;
      if v(1)<='6'
          err.message = lasterr;  % no lasterror function...
      else
          err = lasterror;
      end
      try
          err.message = regexprep(err.message,'Error using ==> [^\n]+\n','');
      catch
          try
              % Another approach, used in Matlab 6 (where regexprep is unavailable)
              startIdx = findstr(err.message,'Error using ==> ');
              stopIdx = findstr(err.message,char(10));
              for idx = length(startIdx) : -1 : 1
                  idx2 = min(find(stopIdx > startIdx(idx)));  %#ok ML6
                  err.message(startIdx(idx):stopIdx(idx2)) = [];
              end
          catch
              % never mind...
          end
      end
      if isempty(findstr(mfilename,err.message))
          % Indicate error origin, if not already stated within the error message
          err.message = [mfilename ': ' err.message];
      end
      if v(1)<='6'
          while err.message(end)==char(10)
              err.message(end) = [];  % strip excessive Matlab 6 newlines
          end
          error(err.message);
      else
          rethrow(err);
      end
  end
% }

%% Internal error processing
function myError(id,msg)
    v = version;
    if (v(1) >= '7')
        error(id,msg);
    else
        % Old Matlab versions do not have the error(id,msg) syntax...
        error(msg);
    end
%end  % myError  %#ok for Matlab 6 compatibility

%% Get object data - methods
function objMethods = getObjMethods(obj)

    % The following was taken from Matlab's methodsview.m function
    if ischar(obj)
        qcls = obj;  % Yair
    else
        qcls = builtin('class', obj);
    end
    [m,d] = methods(qcls,'-full');
    dflag = 1;
    ncols = 6;

    if isempty(d)
        dflag = 0;
        d = cell(size(m,1), ncols);
        for i=1:size(m,1)
            t = find(m{i}=='%',1,'last');
            if ~isempty(t)
                d{i,3} = m{i}(1:t-2);
                d{i,6} = m{i}(t+17:end);
            else
                d{i,3} = m{i};
            end
        end
    end

    r = size(m,1);
    t = d(:,4);
    if ~isempty(d)
        d(:,4:ncols-1) = d(:,5:ncols);
        d(:,ncols) = t;
        %[y,x] = sort(d(:,3)); %#ok y is unused
        [y,x] = sort(strcat(d(:,3),d(:,4))); %#ok y is unused - secondary sort by argument list
    else
        %d = {'','','no methods for this object','','',''};
        x = 1;
    end
    cls = '';
    clss = 0;

    w = num2cell(zeros(1,ncols));

    for i=1:r
        if isempty(cls) && ~isempty(d{i,6})
            t = find(d{i,6}=='.', 1, 'last');
            if ~isempty(t) && strcmp(d{i,3},d{i,6}(t+1:end))
                cls = d{i,6};
                clss = length(cls);
            end
        end
        for j=1:ncols
            if isnumeric(d{i,j})
                d{i,j} = '';
            elseif j==4 && strcmp(d{i,j},'()')
                d{i,j} = '( )';
            elseif j==6
                d{i,6} = deblank(d{i,6});
                if clss > 0 && ...   % If this is the inheritance column & indicates no inheritance
                        (strncmp(d{i,6},qcls,length(qcls)) || ... %Yair
                        (strncmp(d{i,6},cls,clss) &&...
                        (length(d{i,6}) == clss ||...
                        (length(d{i,6}) > clss && d{i,6}(clss+1) == '.'))))
                    d{i,6} = '';     % ...then clear this cell (=not inherited)
                elseif ~isempty(d{i,6})
                    t = find(d{i,6}=='.', 1, 'last');
                    if ~isempty(t)
                        d{i,6} = d{i,6}(1:t-1);
                    end
                end
            end
        end
    end

    if ~dflag
        for i=1:r
            d{i,6} = d{i,5};
            d{i,5} = '';
        end
    end

    datacol = zeros(1, ncols);
    for i=1:r
        for j=1:ncols
            if ~isempty(d{i,j})
                datacol(j) = 1;
                w{j} = max(w{j},length(d{i,j}));
            end
        end
    end

    % HTMLize classes
    %d = regexprep(d,'([^ ,()\[\]]+\.[^ ,()\[\]]*)','<a href="matlab:uiinspect(''$1'');">$1</a>');
    d = regexprep(d,'([^ ,()\[\]]+\.[^ ,()\[\]]*)','<a href="">$1</a>');
    d = regexprep(d,',',' , ');
    d = regexprep(d,'(.+)','<html>$1</html>');

    % Determine the relevant column headers (& widths)
    ch = {};
    hdrs = {'Qualifiers', 'Return Type', 'Name', 'Arguments', 'Other', 'Inherited From'};
    for i=ncols:-1:1
        if datacol(i)
            datacol(i) = sum(datacol(1:i));
            ch{datacol(i)} = hdrs{i};  %#ok
            w{i} = max([length(ch{datacol(i)}),w{i}]);
        end
    end

    if isempty(ch)
        ch = ' ';
        d = {'(no methods)'};
        w = {100};
        x = 1;
        datacol = 1;
    end

    % Return the data
    objMethods.headers = ch;
    objMethods.methods = d(:,find(datacol));  %#ok for ML6 compatibility
    objMethods.widths  = [w{find(datacol)}];  %#ok for ML6 compatibility
    objMethods.sortIdx = x;
%end  % getObjMethods

%% Get object data - properties
function objProps = getObjProps(obj)
    objProps = obj;  %TODO - merge with getPropsData() below
%end  % getObjProps

%% Get object data - callbacks
function objCallbacks = getObjCallbacks(obj)
    objCallbacks = obj;  %TODO - merge with getCbsData() below
%end  % getObjCallbacks

%% Get object data - children
function objChildren = getObjChildren(obj)
    objChildren = obj;  %TODO - merge with getPropsData() below
%end  % getObjChildren

%% Display object data
function hFig = displayObj(obj, objMethods, objProps, objCallbacks, objChildren, objName, hFig)

      % Prepare the data panes
      [methodsPane, hgFlag] = getMethodsPane(objMethods, obj);
      [callbacksPanel, cbTable] = getCbsPane(objCallbacks, false);
      [propsPane, inspectorTable] = getPropsPane(objProps);
      childrenPane = getChildrenPane(objChildren, inspectorTable, propsPane);

      % Prepare the top-bottom JSplitPanes
      import java.awt.* javax.swing.*
	  if ~isempty(inspectorTable)
		  rightPanel = JSplitPane(JSplitPane.VERTICAL_SPLIT, propsPane, childrenPane);
		  leftPanel  = JSplitPane(JSplitPane.VERTICAL_SPLIT, methodsPane, callbacksPanel);
		  set(rightPanel, 'OneTouchExpandable','on', 'ContinuousLayout','on', 'ResizeWeight',0.8);
		  set(leftPanel,  'OneTouchExpandable','on', 'ContinuousLayout','on', 'ResizeWeight',0.7);
	  else
		  rightPanel = childrenPane;
		  leftPanel  = methodsPane;
	  end

      % Prepare the left-right JSplitPane
      hsplitPane = JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightPanel);
      set(hsplitPane,'OneTouchExpandable','on','ContinuousLayout','on','ResizeWeight',0.6);

      % blog link at bottom
      blogLabel = JLabel('<html><center>More undocumented stuff at: <b><a href="">UndocumentedMatlab.com</a></center></html>');
      set(blogLabel,'MouseClickedCallback','web(''http://UndocumentedMatlab.com'')');
      blogLabel.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));
      lowerPanel = JPanel(FlowLayout);
      lowerPanel.add(blogLabel);

      % Display on-screen
      globalPanel = JPanel(BorderLayout);
      globalPanel.add(hsplitPane, BorderLayout.CENTER);
      globalPanel.add(lowerPanel, BorderLayout.SOUTH);

      % Set the figure title
      if isempty(objName)
          objName = 'object of ';
      else
          objName = [objName ' of '];
      end
      if ischar(obj)
          className = obj;
          objName = '';
      else
          className = builtin('class', obj);
      end
      title = ['uiinspect: ' objName 'class ' className];

      % If no figure handle for reuse was specified
      if isempty(hFig)
          % Try to reuse figure with the same title
          hFig = findall(0, '-depth',1, 'type','figure', 'name',title);
      end
      % If no valid figure was found, create a new one - otherwise clear and reuse
      if isempty(hFig)
          hFig = figure;   % existing uiinspector for this object not found - create a new figure
      else
          hFig = hFig(1);  % just in case there's more than one such figure
          clf(hFig);
      end
      set(hFig, 'Name',title, 'NumberTitle','off', 'units','pixel', 'toolbar','none', 'menubar','none');
      pos = get(hFig,'position');
      [obj, hcontainer] = javacomponent(globalPanel, [0,0,pos(3:4)], hFig);
      set(hcontainer,'units','normalized');
      drawnow;

	  % Update the central horizontal divider position based on #methods
      % Note: this only works after the JSplitPane is displayed...
      hDivPos = 0.6;
      if length(objMethods.widths) < 3
          hDivPos = 0.4;
      end
      hsplitPane.setDividerLocation(hDivPos);

	  % Update the right vertical divider position based on #properties
	  if ~isempty(inspectorTable)
		  vDivPos = 0.8;
		  try
			  vDivPos = max(0.2,min(vDivPos,inspectorTable.getRowCount/10));
		  catch
			  % never mind...
		  end
		  rightPanel.setDividerLocation(vDivPos);
	  end

	  % Update the left vertical divider position based on #methods,#callbacks
      vDivPos = max(0.8, 1-cbTable.getRowCount/10);
      try
          % For non-HG handles
          if ~hgFlag
              % Drag the left horizontal divider upward to leave more space for callbacks if not too many methods
              vDivPos = max(0.3,min(vDivPos,length(objMethods.methods)/10));
          end
      catch
          % never mind...
      end
	  if ~isempty(inspectorTable)
		  % auto-hide cbTable if no callbacks
		  if cbTable.getRowCount==1 && cbTable.getColumnCount==1
			  vDivPos = 1;
		  end
		  leftPanel.setDividerLocation(vDivPos);
	  end
      %restoreDbstopError(identifiers);

	  drawnow;
      figure(hFig);  % focus in front

      % Check for a newer version
      checkVersion();

      return;  % debugable point
%end  % displayObj

%% Prepare the property inspector panel
function [propsPane, inspectorTable] = getPropsPane(obj)
      % Prepare the properties pane
      import java.awt.* javax.swing.*
      %classNameLabel = JLabel(['      ' char(obj.class)]);
      classNameLabel = JLabel('      Inspectable object properties');
      classNameLabel.setForeground(Color.blue);
      objProps = updateObjTooltip(obj, classNameLabel);  %#ok unused
      propsPane = JPanel(BorderLayout);
      set(propsPane, 'UserData',classNameLabel);
      propsPane.add(classNameLabel, BorderLayout.NORTH);
      % TODO: Maybe uncomment the following - in the meantime it's unused (java properties are un-groupable)
      %objReg = com.mathworks.services.ObjectRegistry.getLayoutRegistry;
      %toolBar = awtinvoke('com.mathworks.mlwidgets.inspector.PropertyView$ToolBarStyle','valueOf(Ljava.lang.String;)','GROUPTOOLBAR');
      %inspectorPane = com.mathworks.mlwidgets.inspector.PropertyView(objReg, toolBar);
      inspectorPane = com.mathworks.mlwidgets.inspector.PropertyView;
      identifiers = disableDbstopError;  %#ok "dbstop if error" causes inspect.m to croak due to a bug - so workaround
	  try
		  if ischar(obj), error(' '); end  % bail out on class names...
		  inspectorPane.setObject(obj);
	  catch
		  inspectorTable = [];
		  return;
	  end
      inspectorPane.setAutoUpdate(true);
      % TODO: Add property listeners
      inspectorTable = inspectorPane;
      while ~isa(inspectorTable,'javax.swing.JTable')
          inspectorTable = inspectorTable.getComponent(0);
      end
      toolTipText = 'hover mouse over the blue label above to see the full list of properties';
      inspectorTable.setToolTipText(toolTipText);
      try
          % Try JIDE features - see http://www.jidesoft.com/products/JIDE_Grids_Developer_Guide.pdf
          com.mathworks.mwswing.MJUtilities.initJIDE;
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(inspectorTable);
          inspectorTable.setRowAutoResizes(true);
          inspectorTable.getModel.setShowExpert(1);
      catch
          % JIDE is probably unavailable - never mind...
      end
      propsPane.add(inspectorPane, BorderLayout.CENTER);
      %mainPropsPane = JPanel;
      %mainPropsPane.setLayout(BoxLayout(mainPropsPane, BoxLayout.PAGE_AXIS));
      %mainPropsPane.add(inspectorPane);

      % Strip all inspected props from objProps:
      pause(0.1);  %allow the inspector time to load...
      return;
      %{
      rows = inspectorTable.getModel.getRows;
      numRows = rows.size;
      for rowIdx = 0 : numRows-1
          thisRow = rows.get(rowIdx);
          objProps = stripProp(objProps, char(thisRow.getDisplayName));
          for childIdx = 0 : thisRow.getChildrenCount-1
              objProps = stripProp(objProps, char(thisRow.getChildAt(childIdx).getDisplayName));
          end
      end
      %}
%end  % getPropsPane

%% Strip inspected property name from pre-fetched list of object properties
function objProps = stripProp(objProps, inspectedPropName)  %#ok unused
      try
          % search for a case-insensitive match
          %objProps = rmfield(objProps,inspectedPropName);
          propNames = fieldnames(objProps);
          idx = strcmpi(propNames,inspectedPropName);
          objProps = rmfield(objProps,propNames(idx));
      catch
          % never mind - inspectedProp was probably not in objProps
      end
%end  % stripPropName

%% Get callbacks table data
function [cbData, cbHeaders, cbTableEnabled] = getCbsData(obj, stripStdCbsFlag)
      % Initialize
      cbData = {'(no callbacks)'};
      cbHeaders = {'Callback name'};
      cbTableEnabled = false;

      try
          classHdl = classhandle(handle(obj));
          cbNames = get(classHdl.Events,'Name');
          if ~isempty(cbNames) && ~iscom(obj)  %only java-based please...
              cbNames = strcat(cbNames,'Callback');
          end
          propNames = get(classHdl.Properties,'Name');
          propCbIdx = [];
          if ischar(propNames),  propNames={propNames};  end
          if ~isempty(propNames)
              propCbIdx = find(~cellfun(@isempty,regexp(propNames,'(Fcn|Callback)$')));
              cbNames = unique([cbNames; propNames(propCbIdx)]);  %#ok logical is faster but less debuggable...
          end
          if ~isempty(cbNames)
              if stripStdCbsFlag
                  cbNames = stripStdCbs(cbNames);
              end
              if iscell(cbNames)
                  cbNames = sort(cbNames);
              end
              hgHandleFlag = 0;  try hgHandleFlag = ishghandle(obj); catch end
              try
                  obj = handle(obj,'CallbackProperties');
              catch
                  hgHandleFlag = 1;
              end
              if hgHandleFlag
                  % HG handles don't allow CallbackProperties - search only for *Fcn
                  cbNames = propNames(propCbIdx);
              end
              if iscom(obj)
                  cbs = obj.eventlisteners;
                  if ~isempty(cbs)
                      cbNamesRegistered = cbs(:,1);
                      cbData = setdiff(cbNames,cbNamesRegistered);
                      %cbData = charizeData(cbData);
                      if size(cbData,2) > size(cbData(1))
                          cbData = cbData';
                      end
                      cbData = [cbData, cellstr(repmat(' ',length(cbData),1))];
                      cbData = [cbData; cbs];
                      [sortedNames, sortedIdx] = sort(cbData(:,1));
                      sortedCbs = cellfun(@charizeData,cbData(sortedIdx,2),'un',0);
                      cbData = [sortedNames, sortedCbs];
                  else
                      cbData = [cbNames, cellstr(repmat(' ',length(cbNames),1))];
                  end
              elseif iscell(cbNames)
                  %cbData = [cbNames, get(obj,cbNames)'];
                  cbData = cbNames;
                  for idx = 1 : length(cbNames)
                      try
                          cbData{idx,2} = charizeData(get(obj,cbNames{idx}));
                      catch
                          cbData{idx,2} = '(callback value inaccessible)';
                      end
                  end
              else  % only one event callback
                  %cbData = {cbNames, get(obj,cbNames)'};
                  %cbData{1,2} = charizeData(cbData{1,2});
                  try
                      cbData = {cbNames, charizeData(get(obj,cbNames))};
                  catch
                      cbData = {cbNames, '(callback value inaccessible)'};
                  end
              end
              cbHeaders = {'Callback name','Callback value'};
              cbTableEnabled = true;
          end
      catch
          % never mind - use default (empty) data
      end
%end  % getCbsData

%% Get a Matlab object's meta-class object
function mc = getMetaClass(obj)
	  try
		  mc = meta.class.fromName(obj);
	  catch
		  mc = metaclass(obj);
	  end
%end  % getMetaClass

%% Get properties table data
function [propsData, propsHeaders, propTableEnabled] = getPropsData(obj, showMetaData, showInspectedPropsFlag, inspectorTable, cbInspected)
      try
          propNames = {};
		  mc = [];
          try
              %propNames = fieldnames(handle(obj));
              classHdl = classhandle(handle(obj));
              propNames = get(classHdl.Properties,'Name');
          catch
              % maybe a Matlab class...
			  try
				  mc = getMetaClass(obj);
				  propNames = cellfun(@(p) p.Name, mc.Properties, 'un',0);
			  catch
				  %never mind... - might be a classname without any handle
			  end
          end
          
          % Add static class fields, if available
          try
              if ischar(obj)
                  fields = java.lang.Class.forName(obj).getFields;
                  fieldsData = cellfun(@(c)char(toString(c)),cell(fields),'un',0);
                  fieldNames = cellfun(@(c)char(toString(c.getName)),cell(fields),'un',0);
              else
                  fieldNames = fieldnames(obj);
                  try fieldsData = fieldnames(obj,'-full'); catch, end  %#ok
              end
              propNames = [propNames; fieldNames];
              fieldsData = strcat(fieldsData,'%');
          catch
              % never mind...
          end
          if iscell(propNames)
              propNames = unique(propNames);
          end

          %propsData = cell(0,7);
          propsData = {'(no properties)','','','','','',''};
          propsHeaders = {'Name','Type','Value','Get','Set','Visible'};
		  if isempty(mc)
			  propsHeaders{end+1} = 'Default';  % not relevant for Matlab classes
		  else
			  propsHeaders{end+1} = 'Extra';  % Sealed/Dependent/Constant/Abstract/Transient
		  end
          propTableEnabled = false;
          if ~isempty(propNames)

              if ~showInspectedPropsFlag
                  oldPropNames = propNames;
                  % Strip all inspected props
                  pause(0.01);  %allow the inspector time to load...
                  rows = inspectorTable.getModel.getRows;
                  numRows = rows.size;
                  for rowIdx = 0 : numRows-1
                      thisRow = rows.get(rowIdx);
                      [dummy,idx] = setdiff(upper(propNames), upper(char(thisRow.getDisplayName)));
                      propNames = propNames(idx);
                      for childIdx = 0 : thisRow.getChildrenCount-1
                          [dummy,idx] = setdiff(upper(propNames), upper(char(thisRow.getChildAt(childIdx).getDisplayName)));
                          propNames = propNames(idx);
                      end
                  end
                  if ~isequal(oldPropNames,propNames)
                      cbInspected.setVisible(1);
                  end
              end

              % Sort properties alphabetically
              % Note: sorting is already a side-effect of setdiff, but setdiff is not called when showInspectedPropsFlag=1
              if iscell(propNames)
                  propNames = sort(propNames);
              end

              % Strip callback properties
              if ischar(propNames),  propNames = {propNames};  end
              propNames(~cellfun(@isempty,regexp(propNames,'(Fcn|Callback)$'))') = [];
              try
                  mcPropNames = cellfun(@(p) p.Name, mc.Properties, 'un',0);
              catch
                  mcPropNames = propNames;
              end

              % Add property Type & Value data
              errorPrefix       = '<html><font color="red"><i>';      %red
              unsettablePrefix  = '<html><font color="#C0C0C0"><i>';  %light gray
              staticFinalPrefix = '<html><font color="#0000C0"><i>';  %light blue
              for idx = 1 : length(propNames)
                  propName = propNames{idx};
                  try
                      % Find the property's schema.prop data
                      sp = findprop(handle(obj),propName);  %=obj.classhandle.findprop(propName);
                      
                      % Fade non-settable properties (gray italic font)
                      prefix = '';
                      if strcmpi(sp.AccessFlags.PublicSet,'off')
                          prefix = unsettablePrefix;
                      end

                      % Get the property's meta-data
                      propsData{idx,1} = [prefix propName];
                      propsData{idx,2} = '';
                      if ~isempty(sp)
                          propsData{idx,2} = [prefix sp.DataType];
                          propsData{idx,4} = [prefix sp.AccessFlags.PublicGet];
                          propsData{idx,5} = [prefix sp.AccessFlags.PublicSet];
                          propsData{idx,6} = [prefix sp.Visible];
                          if ~strcmp(propName,'FactoryValue')
                              propsData{idx,7} = [prefix charizeData(get(sp,'FactoryValue'))];  % sp.FactoryValue fails...
                          else
                              propsData{idx,7} = '';  % otherwise Matlab crashes...
                          end
                          %propsData{idx,8} = [prefix sp.Description];
                      end
                      % TODO: some fields (see EOL comment below) generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run
                      if strcmpi(sp.AccessFlags.PublicGet,'on') % && ~any(strcmpi(sp.Name,{'FixedColors','ListboxTop','Extent'}))
                          try
                              % Trap warning about unused/depracated properties
                              s = warning('off','all');
                              lastwarn('');
                              value = get(obj, sp.Name);
                              disp(lastwarn);
                              warning(s);
                              propsData{idx,3} = charizeData(value);
                          catch
                              errMsg = regexprep(lasterr, {char(10),'Error using ==> get.Java exception occurred:..'}, {' ',''});
                              propsData{idx,3} = [errorPrefix errMsg];
                              propsData{idx,1} = strrep(propsData{idx,1},propName,[errorPrefix propName]);
                          end
                      else
                          propsData{idx,3} = '(no public getter method)';
                      end
                      %disp({idx,propName})  % for debugging...
				  catch
					  % Try accessing the meta.property metadata
					  try
						  try
							  mp = findprop(obj,propName);
						  catch
							  mp = mc.Properties{strcmpi(mcPropNames,propName)};
						  end

						  % Fade non-settable properties (gray italic font)
						  prefix = '';
						  if ~strcmpi(mp.SetAccess,'public')
							  prefix = unsettablePrefix;
						  end

						  % Get the property's meta-data
						  propsData{idx,1} = [prefix propName];
						  propsData{idx,2} = '';
						  if ~isempty(mp)
							  propsData{idx,2} = [prefix mp.Description];
							  propsData{idx,4} = [prefix mp.GetAccess];
							  propsData{idx,5} = [prefix mp.SetAccess];
							  visibleStr = 'true'; if mp.Hidden, visibleStr='false'; end
							  propsData{idx,6} = [prefix visibleStr];
							  propsData{idx,7} = [prefix charizeBoolData(mp.Sealed,   'Sealed') ...
								                         charizeBoolData(mp.Dependent,' Dependent') ...
														 charizeBoolData(mp.Constant, ' Constant') ...
														 charizeBoolData(mp.Abstract, ' Abstract') ...
														 charizeBoolData(mp.Transient,' Transient')];
							  propsData{idx,7} = strtrim(propsData{idx,7});
						  end
						  if strcmpi(mp.SetAccess,'public')
							  try
								  value = obj.(propName);
								  propsData{idx,3} = charizeData(value);
							  catch
								  errMsg = regexprep(lasterr, {char(10),'Error using ==> get.Java exception occurred:..'}, {' ',''});
								  propsData{idx,3} = [errorPrefix errMsg];
								  propsData{idx,1} = strrep(propsData{idx,1},propName,[errorPrefix propName]);
							  end
						  else
							  propsData{idx,3} = '(no public getter method)';
						  end
					  catch
						  % No schema.prop nor meta.property meta-data...
						  propsData{idx,1} = propName;
						  [propsData{idx,2:7}] = deal('???');
						  try
							  propsData{idx,3} = charizeData(get(obj,propName));
						  catch
							  try
								  if ~ischar(obj)
									  propsData{idx,3} = obj.(propName);
								  else
									  propsData{idx,3} = eval([obj '.' char(propName)]);
								  end
								  propsData{idx,3} = charizeData(propsData{idx,3});
								  fieldIdx = find(~cellfun(@isempty,regexp(fieldsData,['[ .]' propName '[ %]'])));
								  if ~isempty(fieldIdx)
									  thisFieldData = fieldsData{fieldIdx(1)};
									  propsData{idx,2} = regexprep(thisFieldData,[' ' propName '.*'],'');
									  if ~isempty(regexp(thisFieldData,'final ', 'once'))
										  propsData{idx,1} = [staticFinalPrefix propsData{idx,1}];
										  propsData{idx,2} = [unsettablePrefix  propsData{idx,2}];
										  propsData{idx,4} = [unsettablePrefix 'on'];
										  [propsData{idx,5:6}] = deal([unsettablePrefix 'off']);
										  propsData{idx,7} = [unsettablePrefix propsData{idx,3}];
										  propsData{idx,3} = [staticFinalPrefix propsData{idx,3}];
									  end
								  end
							  catch
								  % never mind..
							  end
						  end
					  end
                  end
              end
              propTableEnabled = true;
          end
          if ~showMetaData
              % only show the Name & Value columns
              propsData = propsData(:,[1,3]);
              propsHeaders = propsHeaders(:,[1,3]);
          end
      catch
          disp(lasterr);  rethrow(lasterror)
      end
%end  % getPropsData

%% Convert logical data into a string
function str = charizeBoolData(flagValue,flagName)
      if islogical(flagValue)
		  if flagValue
			  str = flagName;
		  else
			  str = '';
		  end
	  else
          str = charizeData(flagValue);
      end
%end  % charizeBoolData

%% Convert property data into a string
function data = charizeData(data)
      if ~ischar(data) && ~isa(data,'java.lang.String')
          newData = strtrim(evalc('disp(data)'));
          try
              newData = regexprep(newData,'  +',' ');
              newData = regexprep(newData,'Columns \d+ through \d+\s','');
              newData = regexprep(newData,'Column \d+\s','');
          catch
              %never mind...
          end
          if iscell(data)
              newData = ['{ ' newData ' }'];
          elseif isempty(data)
              newData = '';
          elseif isnumeric(data) || islogical(data) || any(ishandle(data)) || numel(data) > 1 %&& ~isscalar(data)
              newData = ['[' newData ']'];
          end
          data = newData;
      elseif ~isempty(data)
          data = ['''' char(data) ''''];
      end
%end  % charizeData

%% Prepare the callbacks pane
function [callbacksPanel, callbacksTable] = getCbsPane(obj, stripStdCbsFlag)
      % Prepare the callbacks pane
      import java.awt.* javax.swing.*
      callbacksPanel = JPanel(BorderLayout);
      [cbData, cbHeaders, cbTableEnabled] = getCbsData(obj, stripStdCbsFlag);
      try
          % Use JideTable if available on this system
          com.mathworks.mwswing.MJUtilities.initJIDE;
          %callbacksTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);  %#ok
          %callbacksTable = eval('com.jidesoft.grid.PropertyTable(callbacksTableModel);');  % prevent JIDE alert by run-time (not load-time) evaluation
          callbacksTable = eval('com.jidesoft.grid.TreeTable(cbData,cbHeaders);');  % prevent JIDE alert by run-time (not load-time) evaluation
          callbacksTable.setRowAutoResizes(true);
          callbacksTable.setColumnAutoResizable(true);
          callbacksTable.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(callbacksTable);
          callbacksTable.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
          callbacksLabel = JLabel(' Callbacks:');  % The column headers are replaced with a header label
          callbacksLabel.setForeground(Color.blue);
          %callbacksPanel.add(callbacksLabel, BorderLayout.NORTH);

          % Add checkbox to show/hide standard callbacks (only if not a HG handle)
          callbacksTopPanel = JPanel;
          callbacksTopPanel.setLayout(BoxLayout(callbacksTopPanel, BoxLayout.LINE_AXIS));
          callbacksTopPanel.add(callbacksLabel);
          hgHandleFlag = 0;  try  hgHandleFlag = ishghandle(obj);  catch,  end  %#ok
          if ~hgHandleFlag && ~iscom(obj)
              callbacksTopPanel.add(Box.createHorizontalGlue);
              jcb = JCheckBox('Hide standard callbacks', stripStdCbsFlag);
              set(jcb, 'ActionPerformedCallback',@cbHideStdCbs_Callback, 'userdata',callbacksTable, 'tooltip','Hide standard Swing callbacks - only component-specific callbacks will be displayed');
              callbacksTopPanel.add(jcb);
          end
          callbacksPanel.add(callbacksTopPanel, BorderLayout.NORTH);
      catch
          % Otherwise, use a standard Swing JTable (keep the headers to enable resizing)
          callbacksTable = JTable(cbData,cbHeaders);
      end
      set(callbacksTable, 'userdata',obj);
      if iscom(obj)
          cbToolTipText = '<html>&nbsp;Callbacks may be ''string'' or @funcHandle';
      else
          cbToolTipText = '<html>&nbsp;Callbacks may be ''string'', @funcHandle or {@funcHandle,arg1,...}';
      end
      %cbToolTipText = [cbToolTipText '<br>&nbsp;{Cell} callbacks are displayed as: [Ljava.lang...'];
      callbacksTable.setToolTipText(cbToolTipText);
      %callbacksTable.setGridColor(inspectorTable.getGridColor);
      cbNameTextField = JTextField;
      cbNameTextField.setEditable(false);  % ensure that the callback names are not modified...
      cbNameCellEditor = DefaultCellEditor(cbNameTextField);
      cbNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
      callbacksTable.getColumnModel.getColumn(0).setCellEditor(cbNameCellEditor);
      if ~cbTableEnabled && callbacksTable.getColumnModel.getColumnCount>1
          callbacksTable.getColumnModel.getColumn(1).setCellEditor(cbNameCellEditor);
      end
      set(callbacksTable.getModel, 'TableChangedCallback',@tbCallbacksChanged, 'UserData',obj);
      cbScrollPane = JScrollPane(callbacksTable);
      cbScrollPane.setVerticalScrollBarPolicy(cbScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
      callbacksPanel.add(cbScrollPane, BorderLayout.CENTER);
      callbacksPanel.setToolTipText(cbToolTipText);
%end  % getCbsPane

%% Prepare the methods pane
function [methodsPane, hgFlag] = getMethodsPane(methodsObj, obj)
      import java.awt.* javax.swing.*
      methodsPane = JPanel(BorderLayout);

      % Get superclass if possible
      superclass = '';
      interfaces = '';
      scSep = '';
      hgFlag = 0;
      labelTypeStr = 'Methods of class';
      mc = [];
      try
          if isjava(obj)
              thisClass = obj.getClass;
          elseif ischar(obj)
              try
                  thisClass = java.lang.Class.forName(obj);
			  catch
				  try
					  classLoader = com.mathworks.jmi.ClassLoaderManager.getClassLoaderManager;
					  thisClass = classLoader.loadClass(obj);
				  catch
					  % one final attempt...
					  thisClass = java.lang.String(obj);
				  end
              end
          elseif ~iscom(obj) && ishghandle(obj)
              hgFlag = 1;
              labelTypeStr = 'Hierarchy of';
          end
          try
              superclass = char(thisClass.getSuperclass.getCanonicalName);
          catch
              % try using metaclass
              try
                  mc = getMetaClass(obj);
                  sc = mc.SuperClasses;
                  for scIdx = 1 : length(sc)
                      if scIdx>1,  superclass = [superclass ', '];  end
                      superclass = [superclass, sc{scIdx}.Name];
                  end
              catch
                  % never mind...
              end
          end
          interfaces = cellfun(@(c)char(toString(c.getName)),thisClass.getInterfaces.cell,'un',0);
      catch
          % never mind...
      end
      if ~isempty(superclass)
          superclass = [' (superclass: ' superclass ')'];
          scSep = '&nbsp;<br>&nbsp;';
      end

      % Add a label
      hyperlink = '';
      if ischar(obj)
          className = char(thisClass.toString);
          className = regexprep(className,'.* ([^ ]+$)','$1');
          if ~isempty(strfind(className,'java'))
              hyperlink = className;
              className = ['<a href="">' className '</a>'];
          end
      else
          className = builtin('class',obj);
          if (isjava(obj) && ~isempty(strfind(className,'java'))) || ~isempty(mc)
              hyperlink = className;
              className = ['<a href="">' className '</a>'];
          end
      end
      labelStr = ['<html>&nbsp;&nbsp;' labelTypeStr ' <b>' className '</b>'];
      methodsLabel = JLabel([labelStr superclass]);

      % Hyperlink the className to Sun's Javadocs, if relevant
      if hyperlink
          try
			  if ~isempty(mc)
				  targetStr = ['help ' hyperlink];
			  else
				  switch com.mathworks.util.PlatformInfo.getVersion  % JVM version
					  case com.mathworks.util.PlatformInfo.VERSION_13
						  prefix = 'j2se/1.3';
					  case com.mathworks.util.PlatformInfo.VERSION_14
						  prefix = 'j2se/1.4.2';
					  case com.mathworks.util.PlatformInfo.VERSION_15
						  prefix = 'j2se/1.5.0';
					  otherwise %case com.mathworks.util.PlatformInfo.VERSION_16
						  prefix = 'javase/6';
				  end
				  url = ['http://java.sun.com/' prefix '/docs/api/' strrep(hyperlink,'.','/') '.html']; % TODO: treat classNames with internal '.'
				  targetStr = ['web(''' url ''')'];
			  end
			  set(methodsLabel,'MouseClickedCallback',targetStr);
			  methodsLabel.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));
          catch
              % never mind...
          end
      end

      % Set extra class info in the title's tooltip
      toolTipStr = ['<html>&nbsp;' labelStr scSep superclass];
      if ~isempty(interfaces) && iscell(interfaces)
          scSep = '&nbsp;<br>&nbsp;';
          toolTipStr = [toolTipStr scSep ' implements:&nbsp;'];
          if length(interfaces) > 1,  toolTipStr=[toolTipStr scSep '&nbsp;&nbsp;&nbsp;'];  end
          for intIdx = 1 : length(interfaces)
              if intIdx>1,  toolTipStr=[toolTipStr scSep '&nbsp;&nbsp;&nbsp;'];  end  %#ok grow
              toolTipStr = [toolTipStr interfaces{intIdx}];      %#ok grow
          end              
      end
      methodsLabel.setToolTipText(toolTipStr);
      methodsLabel.setForeground(Color.blue);
      %methodsPane.add(methodsLabel, BorderLayout.NORTH);
      methodsPanel = JPanel;
      methodsPanel.setLayout(BoxLayout(methodsPanel, BoxLayout.LINE_AXIS));
      methodsPanel.add(methodsLabel);
      methodsPanel.add(Box.createHorizontalGlue);

      % If this is an HG handle, display hierarchy tree instead of methods
      if hgFlag
          paneContents = getHandleTree(obj);
      else
          % Otherwise simply display the object's methods
          paneContents = getMethodsTable(methodsObj, methodsPanel);
      end

      % Attach the title panel and center contents to the methods pane
      methodsPane.add(methodsPanel, BorderLayout.NORTH);
      methodsPane.add(paneContents, BorderLayout.CENTER);
%end  % getMethodsPane

%% Display HG handle hiererchy in a tree
function handleTree = getHandleTree(obj)
      import java.awt.*
      import javax.swing.*

      %handleTree = uitree.
      tree_h = com.mathworks.hg.peer.UITreePeer;
      
      % Use the parent handle as root, unless there is none
      hRoot = handle(get(obj,'parent'));
      if isempty(hRoot) || ~ishandle(hRoot)
          hRoot = obj;
      end
      [icon, iconObj] = getNodeIcon(hRoot);
      rootName = getNodeName(hRoot);
      isLeaf = isempty(allchild(hRoot));
      try
          rootNode = uitreenode('v0', handle(hRoot), rootName, icon, isLeaf);
      catch  % old matlab version don't have the 'v0' option
          rootNode = uitreenode(handle(hRoot), rootName, icon, isLeaf);
      end
      if ~isempty(iconObj)
          rootNode.setIcon(iconObj);
      end
      nodedata.obj = hRoot;
      set(rootNode,'userdata',nodedata);
%      root.setUserObject(hRoot);
      setappdata(rootNode,'childHandle',obj);
      tree_h.setRoot(rootNode);
      handleTree = tree_h.getScrollPane;
      handleTree.setMinimumSize(Dimension(50,50));
      jTreeObj = handleTree.getViewport.getComponent(0);
      jTreeObj.setShowsRootHandles(true)
      jTreeObj.getSelectionModel.setSelectionMode(javax.swing.tree.TreeSelectionModel.SINGLE_TREE_SELECTION);
      %jTreeObj.setVisible(0);
      %jTreeObj.getCellRenderer.setLeafIcon([]);
      %jTreeObj.getCellRenderer.setOpenIcon(figIcon);
      %jTreeObj.getCellRenderer.setClosedIcon([]);

      % Select the root node if it's the current obj
      % Note: we must do so here since all other nodes except the root are processed by expandNode below
      if hRoot == obj
          tree_h.setSelectedNode(rootNode);
      end

      % Set meta-data for use in node expansion
      userdata.initialHandle = obj;
      userdata.inInit = true;
      userdata.jTree = jTreeObj;
      set(tree_h, 'userdata',userdata);

      % Set the callback functions
      set(tree_h, 'NodeExpandedCallback', {@nodeExpanded, tree_h});
      set(tree_h, 'NodeSelectedCallback', @nodeSelected);

      % Set the tree mouse-click callback
% Note: default actions (expand/collapse) will still be performed?
      % Note: MousePressedCallback is better than MouseClickedCallback
      %       since it fires immediately when mouse button is pressed,
      %       without waiting for its release, as MouseClickedCallback does
      set(jTreeObj, 'MousePressedCallback', @treeMousePressedCallback);  % context (right-click) menu
      set(jTreeObj, 'MouseMovedCallback',   @treeMouseMovedCallback);    % mouse hover tooltips

      % Pre-expand hierarchy (parent & all grandchildren downward, but not current siblings)
      expandNode(jTreeObj, tree_h, rootNode, 0);
      jTreeObj.expandRow(0);  % To fix intermittent cases of unexpansion - see TODO list below

      % Update userdata
      userdata.inInit = false;
      set(tree_h, 'userdata',userdata);
%end  % getHandleTree

%% Set up the uitree context (right-click) menu
function jmenu = setTreeContextMenu(obj,node)
      % Prepare the context menu (note the use of HTML labels)
      import javax.swing.*
      handleValue = double(obj);
      titleStr = getNodeTitleStr(obj,node);
      menuItem0 = JMenuItem(titleStr);
      set(menuItem0,'Enabled','off','Armed','off');
      menuItem1 = JMenuItem('Inspect in this window');
      menuItem2 = JMenuItem('Inspect in a new window');
      menuItem3 = JMenuItem('Copy handle value to clipboard');
      menuItem4 = JMenuItem('Request focus (bring to front)');
      menuItem5 = JMenuItem('Inspect underlying Java object');
      menuItem6 = JMenuItem('View object in Java hierarchy');

      % Set the menu items' callbacks
      set(menuItem1,'ActionPerformedCallback',{@inspectHandle,obj,0});
      set(menuItem2,'ActionPerformedCallback',{@inspectHandle,obj,1});
      set(menuItem3,'ActionPerformedCallback',sprintf('clipboard(''copy'',%.99g)',handleValue));
      set(menuItem4,'ActionPerformedCallback',{@requestFocus,obj});
      set(menuItem5,'ActionPerformedCallback',{@inspectJavaObj,obj,0});
      set(menuItem6,'ActionPerformedCallback',{@inspectJavaObj,obj,1});

      % Add all menu items to the context menu (with internal separator)
      jmenu = JPopupMenu;
      jmenu.add(menuItem0);
      jmenu.addSeparator;
      jmenu.add(menuItem1);
      jmenu.add(menuItem2);
      jmenu.addSeparator;
      jmenu.add(menuItem3);
      jmenu.add(menuItem4);
      jmenu.addSeparator;
      jmenu.add(menuItem5);
      jmenu.add(menuItem6);
%end  % setTreeContextMenu

%% Inspect a specified handle
function inspectHandle(hTree, eventData, obj, newFigureFlag)  %#ok hTree & eventData are unused
    % Ensure the object handle is valid
    if ~ishandle(obj)
        msgbox('The selected object does not appear to be a valid handle as defined by the ishandle() function. Perhaps this object was deleted after this hierarchy tree was already drawn. Refresh this tree by selecting a valid node handle and then retry.','FindJObj','warn');
        beep;
        return;
    end

    try
        % Run uiinspect on the specified object handle, in the requested window
        hFig = gcf;
        if newFigureFlag
            hFig = figure;
        end
        uiinspect(obj,hFig);
    catch
        % never mind...
        dispError;
    end
%end  % inspectHandle

%% Inspect the underlying Java object of a handle
function inspectJavaObj(hTree, eventData, obj, newFigureFlag)  %#ok hTree & eventData are unused
    try
        % If FINDJOBJ is not installed
        if isempty(which('findjobj'))

            % Ask the user whether to download FINDJOBJ (YES, no, no & don't ask again)
            answer = questdlg({'The Java inspector requires FINDJOBJ from Matlab Central File Exchange. FINDJOBJ was also created by Yair Altman, like this UIInspect utility.','','Download & install FINDJOBJ?'},'FindJObj','Yes','No','Yes');
            switch answer
                case 'Yes'  % => Yes: download & install
                    try
                        % Download FINDJOBJ
                        baseUrl = 'http://www.mathworks.com/matlabcentral/fileexchange/14317';
                        fileUrl = [baseUrl '?controller=file_infos&download=true'];
                        file = urlread(fileUrl);
                        file = regexprep(file,[char(13),char(10)],'\n');  %convert to OS-dependent EOL

                        % Install...
                        newPath = fullfile(fileparts(which(mfilename)),'findjobj.m');
                        fid = fopen(newPath,'wt');
                        fprintf(fid,'%s',file);
                        fclose(fid);
                    catch
                        % Error downloading: inform the user
                        msgbox(['Error in downloading: ' lasterr], 'FindJObj', 'warn');
                        web(baseUrl);
                    end

                    % ...and now run it...
                    %pause(0.1);
                    drawnow;
                    dummy = which('findjobj');  %#ok used only to load into memory (could also use rehash)
                    inspectJavaObjInternal(obj,newFigureFlag);
                    return;

                otherwise
                    % forget it...
            end
        else
            % FindJobj is installed - run it on the specified handle
            inspectJavaObjInternal(obj,newFigureFlag);
        end
    catch
        % Never mind...
        dispError
    end
%end  % inspectJavaObj

%% Try to find and inspect the underlying Java object of a component handle
function inspectJavaObjInternal(obj,newFigureFlag)

    % Ensure the object handle is valid
    if ~ishandle(obj)
        msgbox('The selected object does not appear to be a valid handle as defined by the ishandle() function. Perhaps this object was deleted after this hierarchy tree was already drawn. Refresh this tree by selecting a valid node handle and then retry.','FindJObj','warn');
        beep;
        return;
    end

    try
        % Change the mouse pointer to an hourglass until we're done
        hFig = gcf;
        oldPointer = get(hFig,'pointer');
        set(hFig,'pointer','watch')
        drawnow;

        if newFigureFlag
            % Interactive (GUI) FindJObj
            findjobj(obj);
        else
            % Non-interactive FindJObj
            jObj = findjobj(obj);
            if ~isempty(jObj)
                % Object found - inspect it in a new figure window
                jObj = jObj(1);  % several instances may be found - only inspect the first found instance
                try
                    % Try to strip Matlab javahandle wrapper
                    jObj = jObj.java;
                catch
                    % never mind...
                end
                uiinspect(jObj);
            else
                % Object not found - try interactive (GUI) FindJObj
                answer = questdlg({['No underlying Java object was found for this ' get(handle(obj),'type') ' handle.'],'','Try to find it using the Java hierarchy tree?'},'FindJObj','Yes','No','Yes');
                switch answer
                    case 'Yes',  findjobj(obj);
                    otherwise,   % Do nothing...
                end
            end
        end
    catch
        dispError
    end

    % Restore the figure pointer to its original value
    set(hFig,'pointer',oldPointer)
%end  % inspectJavaObjInternal

%% Request focus for the specified handle
function requestFocus(hTree, eventData, obj)  %#ok hTree & eventData are unused
    % Ensure the object handle is valid
    if isjava(obj)
        obj.requestFocus;
    elseif ~ishandle(obj)
        msgbox('The selected object does not appear to be a valid handle as defined by the ishandle() function. Perhaps this object was deleted after this hierarchy tree was already drawn. Refresh this tree by selecting a valid node handle and then retry.','FindJObj','warn');
        beep;
        return;
    end

    try
        foundFlag = 0;
        while ~foundFlag
            if isempty(obj),  return;  end  % sanity check
            type = get(obj,'type');
            obj = double(obj);
            foundFlag = any(strcmp(type,{'figure','axes','uicontrol'}));
            if ~foundFlag
                obj = get(obj,'Parent');
            end
        end
        feval(type,obj);
    catch
        % never mind...
        dispError;
    end
%end  % requestFocus

%% Set the mouse-press callback
function treeMousePressedCallback(hTree, eventData)
    if eventData.isMetaDown  % right-click is like a Meta-button
        % Get the clicked node
        clickX = eventData.getX;
        clickY = eventData.getY;
        jtree = eventData.getSource;
        treePath = jtree.getPathForLocation(clickX, clickY);
        try
            % Modify the context menu based on the clicked node
            node = treePath.getLastPathComponent;
            userdata = get(node,'userdata');
            obj = userdata.obj;
            jmenu = setTreeContextMenu(obj,node);

            % TODO: remember to call jmenu.remove(item) in item callback
            % or use the timer hack shown here to remove the item:
%            timerFcn = {@menuRemoveItem,jmenu,item};
%            start(timer('TimerFcn',timerFcn,'StartDelay',0.2));

            % Display the (possibly-modified) context menu
            jmenu.show(jtree, clickX, clickY);
            jmenu.repaint;
            
            % This is for debugging:
            userdata.tree = jtree;
            setappdata(gcf,'uiinspect_hgtree',userdata)
        catch
            % clicked location is NOT on top of any node
            % Note: can also be tested by isempty(treePath)
        end
    end
%end

%% Remove the extra context menu item after display
function menuRemoveItem(hObj,eventData,jmenu,item) %#ok unused
    jmenu.remove(item);
%end  % menuRemoveItem

%% Get the title for the tooltip and context (right-click) menu
function nodeTitleStr = getNodeTitleStr(obj,node)
    try
        handleValueStr = sprintf('#: <font color="blue"><b>%.99g<b></font>',double(obj));
        try
            type = '';
            type = get(obj,'type');
            type(1) = upper(type(1));
        catch
            if ~ishandle(obj)
                type = ['<font color="red"><b>Invalid <i>' char(node.getName) '</i>'];
                handleValueStr = '!!!</b></font><br>Perhaps this handle was deleted after this UIInspect tree was<br>already drawn. Try to refresh by selecting any valid node handle';
            end
        end
        nodeTitleStr = sprintf('<html>%s handle %s',type,handleValueStr);
        try
            % If the component is invisible, state this in the tooltip
            if strcmp(get(obj,'Visible'),'off')
                nodeTitleStr = [nodeTitleStr '<br><center><font color="gray"><i>Invisible</i></font>'];
            end
        catch
            % never mind...
        end
    catch
        dispError
    end
%end  % getNodeTitleStr

%% Handle tree mouse movement callback - used to set the tooltip & context-menu
function treeMouseMovedCallback(hTree, eventData)
      try
          x = eventData.getX;
          y = eventData.getY;
          jtree = eventData.getSource;
          treePath = jtree.getPathForLocation(x, y);
          try
              % Set the tooltip string based on the hovered node
              node = treePath.getLastPathComponent;
              userdata = get(node,'userdata');
              obj = userdata.obj;
              tooltipStr = getNodeTitleStr(obj,node);
              set(hTree,'ToolTipText',tooltipStr)
          catch
              % clicked location is NOT on top of any node
              % Note: can also be tested by isempty(treePath)
          end
      catch
          dispError;
      end
      return;  % denug breakpoint
%end  % treeMouseMovedCallback

%% Find a tree node's type for its name
function [nodeName, nodeTitle] = getNodeName(hndl)
    try
        if isnumeric(hndl)
            hndl = handle(hndl);
        end

        % Initialize (just in case one of the succeding lines croaks)
        nodeName = '';
        if ~ismethod(hndl,'getClass')
            try
                nodeName = hndl.class;
            catch
                nodeName = hndl.type;  % last-ditch try...
            end
        else
            nodeName = hndl.getClass.getSimpleName;
        end
        nodeType = nodeName;

        % Strip away the package name, leaving only the regular classname
        if ~isempty(nodeName) && ischar(nodeName)
            nodeName = java.lang.String(nodeName);
            nodeName = nodeName.substring(nodeName.lastIndexOf('.')+1);
        end
        if (nodeName.length == 0)
            % fix case of anonymous internal classes, that do not have SimpleNames
            try
                nodeName = hndl.getClass.getName;
                nodeName = nodeName.substring(nodeName.lastIndexOf('.')+1);
            catch
                % never mind - leave unchanged...
            end
        end

        % Get any unique identifying string (if available in one of several fields)
        labelsToCheck = {'label','title','text','string','displayname','toolTipText','TooltipString','actionCommand','name','Tag','style','UIClassID'};
        nodeTitle = '';
        strField = '';  %#ok - used for debugging
        while ((~isa(nodeTitle,'java.lang.String') && ~ischar(nodeTitle)) || isempty(nodeTitle)) && ~isempty(labelsToCheck)
            try
                nodeTitle = get(hndl,labelsToCheck{1});
                strField = labelsToCheck{1};  %#ok - used for debugging
            catch
                % never mind - probably missing prop, so skip to next one
            end
            labelsToCheck(1) = [];
        end
        if length(nodeTitle) ~= numel(nodeTitle)
            % Multi-line - convert to a long single line
            nodeTitle = nodeTitle';
            nodeTitle = nodeTitle(:)';
        end
        extraStr = regexprep(nodeTitle,{sprintf('(.{35,%d}).*',min(35,length(nodeTitle)-1)),' +'},{'$1...',' '},'once');
        if ~isempty(extraStr)
            if ischar(extraStr)
                nodeName = nodeName.concat(' (''').concat(extraStr).concat(''')');
            else
                nodeName = nodeName.concat(' (').concat(num2str(extraStr)).concat(')');
            end
            %nodeName = nodeName.concat(strField);
        end
        
        % Append the numeric handle value if no extra text was found to describe this handle
        if strcmp(char(nodeName),char(nodeType))
            if strcmp(char(nodeType),'figure') && strcmp(get(hndl,'NumberTitle'),'on')
                nodeName = sprintf('%s (''Figure %d'')',char(nodeName),double(hndl));
            else
                %nodeName = sprintf('<html>%s <font size=-3>(%.99g)',char(nodeName),double(hndl));
                % Never mind - the handle value will be presented in the tooltip
            end
        end
    catch
        % Never mind - use whatever we have so far
        %dispError
    end
%end  % getNodeName

%% Find a suitable node icon (the default icons for most types is an ugly gray box...)
function [icon, iconObj] = getNodeIcon(obj)
    icon = [];
    iconObj = [];
    try
        type = lower(get(obj,'type'));
        %disp(type)
        switch type
            case 'root',      icon = 'matlabicon.gif';
            case 'figure',    icon = 'figureicon.gif';
            case 'uimenu',    
                              if ~isempty(allchild(obj))
                                  icon = 'foldericon.gif';
                              else
                                  icon = 'text_arrow.gif';
                              end
            case 'text',      icon = 'tool_text.gif';
            case 'image',     icon = 'tool_legend.gif';
            case 'uitoolbar', icon = 'greenarrowicon.gif';
            case {'uipushtool','uitoggletool'}
                              icon = [];
                              cdata = get(obj,'cdata');
                              cdata(isnan(cdata)) = 1;  % transparent => white (default=black)
                              iconObj = im2java(cdata);
        end
        if ~isempty(icon) && ischar(icon)
            % Ensure the icon file exists - if not then use the default icon
            icon = fullfile(matlabroot, 'toolbox/matlab/icons', icon);
            iconfile = dir(icon);
            if isempty(iconfile)
                icon = [];
            end
        end
    catch
        dispError;
    end
%end  % getNodeIcon

%% Recursively expand all nodes (except toolbar/menubar) in startup
function expandNode(tree, tree_h, parentNode, parentRow)
        try
            if nargin < 4
                parentPath = javax.swing.tree.TreePath(parentNode.getPath);
                parentRow = tree.getRowForPath(parentPath);
            end
            tree.expandRow(parentRow);
            numChildren = parentNode.getChildCount;
            if (numChildren == 0)
                pause(0.001);  % as short as possible...
                drawnow;
            end
            nodesToUnExpand = {'FigureMenuBar','MLMenuBar','MJToolBar','Box','uimenu','uitoolbar','ScrollBar'};
            numChildren = parentNode.getChildCount;
            for childIdx = 0 : numChildren-1
                childNode = parentNode.getChildAt(childIdx);

                % Select the current node
                try
                    selectedNodeFlag = 0;
                    nodedata = get(childNode, 'userdata');
                    userdata = get(tree_h, 'userdata');
                    if userdata.initialHandle == nodedata.obj
                        pause(0.001);  % as short as possible...
                        drawnow;
                        tree_h.setSelectedNode(childNode);
                        selectedNodeFlag = 1;
                    end
                catch
                    % never mind...
                    dispError
                end

                % Expand all non-leaf nodes beneath the current obj, except toolbar/menu items
                if ~childNode.isLeafNode
                    normalizedNodeName = strtok(childNode.getName.char);
                    if selectedNodeFlag || (nargin==4 && handle(userdata.initialHandle)==handle(0)) || ...
                       ((nargin < 4) && ~any(strcmp(normalizedNodeName,nodesToUnExpand)))
                        expandNode(tree, tree_h, childNode);
                    end
                end
            end
        catch
            % never mind...
            dispError
        end
%end  % expandNode

%% Expand tree node
function nodeExpanded(src, evd, tree)  %#ok src is unused
    try
        % tree = handle(src);
        % evdsrc = evd.getSource;
        evdnode = evd.getCurrentNode;

        if ~tree.isLoaded(evdnode)

            % Get the list of children TreeNodes
            childnodes = getChildrenNodes(tree, evdnode);
            if isempty(childnodes)
                return;
            end

            % If we have a single child handle, wrap it within a javaArray for tree.add() to "swallow"
            if (length(childnodes) == 1)
                chnodes = childnodes;
                childnodes = javaArray('com.mathworks.hg.peer.UITreeNode', 1);
                childnodes(1) = java(chnodes);
            end

            % Add child nodes to the current node
            tree.add(evdnode, childnodes);
            tree.setLoaded(evdnode, true);
        end
    catch
        dispError
    end
%end  % nodeExpanded

%% Get list of children nodes
function nodes = getChildrenNodes(tree, parentNode)  %#ok tree is unused
        try
            nodes = handle([]);
            nodedata = get(parentNode,'userdata');

            % Get the HG handles of all parentNode's direct children
            %children = findall(nodedata.obj,'-depth',1);
            %children(children==double(nodedata.obj)) = [];
            children = allchild(nodedata.obj);
            if isempty(children)
                return;
            end

            %iconpath = [matlabroot, '/toolbox/matlab/icons/'];
            numChildren = length(children);
            for cIdx = 1 : numChildren
                thisChild = children(cIdx);
                thisChildHandle = handle(thisChild);
                childName = getNodeName(thisChildHandle);
                try
                    visible = strcmp(thisChildHandle.Visible,'on');
                    if ~visible
                        childName = ['<HTML><i><font color="gray">' char(childName) '</font></i></html>'];  %#ok grow
                    end
                catch
                    % never mind...
                end
                [icon, iconObj] = getNodeIcon(thisChild);
                isLeaf = isempty(findall(thisChild));
                try
                    nodes(cIdx) = uitreenode('v0', thisChildHandle, childName, icon, isLeaf);
                catch  % old matlab version don't have the 'v0' option
                    try
                        nodes(cIdx) = uitreenode(thisChildHandle, childName, icon, isLeaf);
                    catch
                        % probably an invalid handle - ignore...
                    end
                end
                if ~isempty(iconObj)
                    nodes(cIdx).setIcon(iconObj);
                end

                % Add the handler to the node's internal data
                % Note: could also use 'userdata', but setUserObject() is recommended for TreeNodes
                % Note2: however, setUserObject() sets a java *BeenAdapter object for HG handles instead of the required original class, so use setappdata
                % Note3: the following will error if invalid handle - ignore
                try
                    %nodes(cIdx).setUserObject(thisChildHandle);
                    setappdata(nodes(cIdx),'childHandle',thisChildHandle);
                    nodedata.obj = thisChildHandle;
                    set(nodes(cIdx),'userdata',nodedata);
                catch
                    % never mind (probably an invalid handle) - leave unchanged (like a leaf)
                end
            end
        catch
            % Never mind - leave unchanged (like a leaf)
            %error('YMA:findjobj:UnknownNodeType', 'Error expanding component tree node');
            dispError
        end
%end  % getChildrenNodes

%% Select tree node
function nodeSelected(src, evd, hFig)
    try
        rescanFlag = 0;
        %nodeHandle = evd.getCurrentNode.getUserObject;
        nodedata = get(evd.getCurrentNode,'userdata');
        nodeHandle = nodedata.obj;
        userdata = get(src,'userdata');
        if ~isempty(nodeHandle) && ~isempty(userdata) && ~userdata.inInit

            % Ensure the object handle is valid
            if ~ishandle(nodeHandle)
                msgbox('The selected object does not appear to be a valid handle as defined by the ishandle() function. Perhaps this object was deleted after this hierarchy tree was already drawn. Refresh this tree by selecting a valid node handle and then retry.','FindJObj','warn');
                beep;
                return;
            end

            % Get the current uiinspect figure handle
            hFig = [];
            try
                hFig = ancestor(src,'figure');   % TODO - this fails: need to find a way to pass hFig...
                if isempty(hFig)
                    hFig = gcf;
                end
            catch
                hFig = gcf;
            end

            % Temoprarily modify the curpor pointer to an hourglass
            rescanFlag = 1;
            oldPointer = get(hFig,'pointer');
            set(hFig,'pointer','watch')
            drawnow;

            % Re-inspect the selected handle (rename the variable 'handle' for a nice title name...
            handle = nodeHandle;
            uiinspect(handle,hFig);

            % TODO: Auto-highlight selected object (?)
            %nodeHandle.requestFocus;
        end
    catch
        dispError
    end

    % Restore the figure pointer to its original value
    if rescanFlag
        set(hFig,'pointer',oldPointer)
    end
%end  % nodeSelected

%% Display object methods in a table
function methodsTable = getMethodsTable(methodsObj, methodsPanel)

      % Method A: taken from Matlab's methodsview function (slightly modified)
      %{
      ncols = length(methodsObj.widths);
      b = com.mathworks.mwt.MWListbox;
      b.setColumnCount(ncols);
      wb = 0;
      for i=1:ncols,
          wc = 7.5 * methodsObj.widths(i);
          b.setColumnWidth(i-1, wc);
          b.setColumnHeaderData(i-1, methodsObj.headers{i});
          wb = wb+wc;
      end;

      co = b.getColumnOptions;
      set(co, 'HeaderVisible', 'on');
      set(co, 'Resizable', 'on');
      b.setColumnOptions(co);
      set(b.getHScrollbarOptions,'Visibility','Always');  %Yair: fix HScrollbar bug

      ds = javaArray('java.lang.String', ncols);
      for i=1:size(methodsObj.methods,1)
          for j=1:ncols
              ds(j) = java.lang.String(methodsObj.methods{methodsObj.sortIdx(i),j});
          end;
          b.addItem(ds);
      end;
      %}

      % Create a checkbox for extra methods info
      import javax.swing.*
      cbExtra = JCheckBox('Extra', 0);
      methodsPanel.add(cbExtra);

      % Hide the extra data by default
      headers = methodsObj.headers;
      validIdx = strcmpi(headers,'Return Type') | strcmpi(headers,'Name') | strcmpi(headers,'Arguments');
      headers(~validIdx) = [];
      if ~isempty(headers)
          data = methodsObj.methods(methodsObj.sortIdx,validIdx);
          if all(validIdx)
              cbExtra.setVisible(0);  % hide the Extra checkbox if no extra info is available
          end
      else
          data = methodsObj.methods(methodsObj.sortIdx,1);
          headers = {' '};
          cbExtra.setVisible(0);  % hide the Extra checkbox
      end

      % Method B: use a JTable - looks & refreshes much better...
      try
          com.mathworks.mwswing.MJUtilities.initJIDE;
          b = eval('com.jidesoft.grid.TreeTable(data, headers);');  % prevent JIDE alert by run-time (not load-time) evaluation
          b.setRowAutoResizes(true);
          b.setColumnAutoResizable(true);
          b.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(b);
      catch
          try
              b = JTable(data, headers);
          catch
              % probably no data - so create an empty table
              b = JTable;
          end
      end

      % Hide the column header if only one column is shown
      if length(headers) < 2
          b.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
          %cbExtra.setVisible(0);  % hide the Extra checkbox
      end

      % Add hyperlink support
      try
          set(handle(b,'callbackproperties'),'MousePressedCallback',@tbMousePressed,'MouseMovedCallback',@tbMouseMoved);
      catch
          % never mind...
      end

      b.setShowGrid(0);
      scroll = JScrollPane(b);
      scroll.setVerticalScrollBarPolicy(scroll.VERTICAL_SCROLLBAR_AS_NEEDED);
      scroll.setHorizontalScrollBarPolicy(scroll.HORIZONTAL_SCROLLBAR_AS_NEEDED);
      b.setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
      b.setAutoResizeMode(b.AUTO_RESIZE_SUBSEQUENT_COLUMNS)
      %b.setEnabled(0);
      cbNameTextField = JTextField;
      cbNameTextField.setEditable(false);  % ensure that the method names are not modified...
      cbNameCellEditor = DefaultCellEditor(cbNameTextField);
      cbNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
      for colIdx = 1:length(headers)
          b.getColumnModel.getColumn(colIdx-1).setCellEditor(cbNameCellEditor);
      end

      % Set meta-data for the Extra checkbox callback
      methodsObj.tableObj = b;
      set(cbExtra, 'ActionPerformedCallback',@updateMethodsTable, 'userdata',methodsObj, 'tooltip','Also show qualifiers, interrupts & inheritance');
      
      % Return the scrollpane
      methodsTable = scroll;
%end  % getMethodsTable

%% Prepare the children pane (Display additional props that are not inspectable by the inspector)
function othersPane = getChildrenPane(obj, inspectorTable, propsPane)
      import java.awt.* javax.swing.*

      % Label (for inspectable objects only)
      othersPane = JPanel(BorderLayout);
      othersTopPanel = JPanel;
      othersTopPanel.setLayout(BoxLayout(othersTopPanel, BoxLayout.LINE_AXIS));
	  othersLabel = JLabel(' Object properties');
	  if ~isempty(inspectorTable)
		  othersLabel.setText(' Other properties');
		  othersLabel.setToolTipText('Properties not inspectable by the inspect table above');
      else
          try
              classNameLabel = get(propsPane, 'UserData');
              othersLabel.setToolTipText(classNameLabel.getToolTipText);
          catch
              % never mind...
          end
	  end
	  othersLabel.setForeground(Color.blue);
	  ud.othersLabel = othersLabel;
	  othersTopPanel.add(othersLabel);
	  %othersPane.add(othersLabel, BorderLayout.NORTH);

      % Add checkbox to show/hide meta-data
      othersTopPanel.add(Box.createHorizontalGlue);
      cbMetaData = JCheckBox('Meta-data', 0);
      ud.cbMetaData = cbMetaData;
      othersTopPanel.add(cbMetaData);

	  % Add checkbox to show/hide inspectable properties (for inspectable objects only)
	  if ~isempty(inspectorTable)
		  cbInspectable = JCheckBox('Inspectable', 0);
		  cbInspectable.setVisible(0);
		  ud.cbInspected = cbInspectable;
		  othersTopPanel.add(cbInspectable);
	  else
		  cbInspectable = [];
	  end
      othersPane.add(othersTopPanel, BorderLayout.NORTH);

      % Data table
      [propsData, propsHeaders] = getPropsData(obj, false, isempty(inspectorTable), inspectorTable, cbInspectable);
      try
          % Use JideTable if available on this system
          com.mathworks.mwswing.MJUtilities.initJIDE;
          %propsTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);  %#ok
          %propsTable = eval('com.jidesoft.grid.PropertyTable(propsTableModel);');  % prevent JIDE alert by run-time (not load-time) evaluation
          propsTable = eval('com.jidesoft.grid.TreeTable(propsData,propsHeaders);');  % prevent JIDE alert by run-time (not load-time) evaluation
          propsTable.setRowAutoResizes(true);
          propsTable.setColumnAutoResizable(true);
          propsTable.setColumnResizable(true);
          jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
          jideTableUtils.autoResizeAllColumns(propsTable);
          %propsTable.setTableHeader([]);  % hide the column headers since now we can resize columns with the gridline
      catch
          % Otherwise, use a standard Swing JTable (keep the headers to enable resizing)
          propsTable = JTable(propsData,propsHeaders);
      end
      %propsToolTipText = '<html>&nbsp;Callbacks may be ''strings'' or {@myFunc,arg1,...}';
      %propsTable.setToolTipText(propsToolTipText);
      %propsTable.setGridColor(inspectorTable.getGridColor);
      propNameTextField = JTextField;
      propNameTextField.setEditable(false);  % ensure that the prop names are not modified...
      propNameCellEditor = DefaultCellEditor(propNameTextField);
      propNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
	  if isempty(inspectorTable)
		  readOnlyCols = 0 : propsTable.getColumnModel.getColumnCount-1;
	  else
		  readOnlyCols = 0;
	  end
	  for readOnlyIdx = readOnlyCols
		  propsTable.getColumnModel.getColumn(readOnlyIdx).setCellEditor(propNameCellEditor);
	  end
      ud.obj = obj;
      ud.inspectorTable = inspectorTable;
      set(propsTable.getModel, 'TableChangedCallback',@tbPropChanged, 'UserData',ud);
      scrollPane = JScrollPane(propsTable);
      scrollPane.setVerticalScrollBarPolicy(scrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
      %scrollPane.setHorizontalScrollBarPolicy(scrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
      othersPane.add(scrollPane, BorderLayout.CENTER);

      % Preserve persistent info in the propsTable's userdata
      set(cbMetaData,    'ActionPerformedCallback',@updatePropsTable, 'userdata',propsTable, 'tooltip','Also show property meta-data (type, visibility, get/set availability, etc.)');
      set(cbInspectable, 'ActionPerformedCallback',@updatePropsTable, 'userdata',propsTable, 'tooltip','Also show inspectable properties (displayed in the table above)');
      set(propsTable, 'userdata',ud);
%end  % getChildrenPane

%% "dbstop if error" causes inspect.m to croak due to a bug - so workaround by temporarily disabling this dbstop
function identifiers = disableDbstopError
    dbStat = dbstatus;
    idx = find(strcmp({dbStat.cond},'error'));
    identifiers = [dbStat(idx).identifier];
    if ~isempty(idx)
        dbclear if error;
        msgbox('''dbstop if error'' had to be disabled due to a Matlab bug that would have caused Matlab to crash.', mfilename, 'warn');
    end
%end  % disableDbstopError

%% Restore any previous "dbstop if error"
function restoreDbstopError(identifiers)  %#ok unused
    for itemIdx = 1 : length(identifiers)
        eval(['dbstop if error ' identifiers{itemIdx}]);
    end
%end  % restoreDbstopError

%% Strip standard Swing callbacks from a list of events
function evNames = stripStdCbs(evNames)
    try
        stdEvents = {'AncestorAdded',  'AncestorMoved',    'AncestorRemoved', 'AncestorResized', ...
                     'ComponentAdded', 'ComponentRemoved', 'ComponentHidden', ...
                     'ComponentMoved', 'ComponentResized', 'ComponentShown', ...
                     'FocusGained',    'FocusLost',        'HierarchyChanged', ...
                     'KeyPressed',     'KeyReleased',      'KeyTyped', ...
                     'MouseClicked',   'MouseDragged',     'MouseEntered',  'MouseExited', ...
                     'MouseMoved',     'MousePressed',     'MouseReleased', 'MouseWheelMoved', ...
                     'PropertyChange', 'VetoableChange',   ...
                     'CaretPositionChanged', 'InputMethodTextChanged'};
        evNames = setdiff(evNames,strcat(stdEvents,'Callback'))';
    catch
        % Never mind...
        disp(lasterr);  rethrow(lasterror)
    end
%end  % stripStdCbs

%% Callback function for <Hide standard callbacks> checkbox
function cbHideStdCbs_Callback(src, evd, varargin)
    try
        % Update callbacks table data according to the modified checkbox state
        callbacksTable = get(src,'userdata');
        obj = get(callbacksTable, 'userdata');
        [cbData, cbHeaders] = getCbsData(obj, evd.getSource.isSelected);
        callbacksTableModel = javax.swing.table.DefaultTableModel(cbData,cbHeaders);
        set(callbacksTableModel, 'TableChangedCallback',@tbCallbacksChanged, 'UserData',handle(obj,'CallbackProperties'));
        callbacksTable.setModel(callbacksTableModel)
        try
            % Try to auto-resize the columns
            callbacksTable.setRowAutoResizes(true);
            jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
            jideTableUtils.autoResizeAllColumns(callbacksTable);
        catch
            % JIDE is probably unavailable - never mind...
        end
    catch
        % Never mind...
        %disp(lasterr);  rethrow(lasterror)
    end
%end  % cbHideStdCbs_Callback

%% Update the methods table following a checkbox modification
function updateMethodsTable(src, evd, varargin)  %#ok partially unused
    try
        % Update callbacks table data according to the modified checkbox state
        methodsObj = get(src,'userdata');
        data = methodsObj.methods(methodsObj.sortIdx,:);
        headers = methodsObj.headers;
        if ~evd.getSource.isSelected  % Extra data requested
            validIdx = strcmpi(headers,'Return Type') | strcmpi(headers,'Name') | strcmpi(headers,'Arguments');
            headers(~validIdx) = [];
            data(:,~validIdx) = [];
        end
        tableModel = javax.swing.table.DefaultTableModel(data,headers);
        methodsObj.tableObj.setModel(tableModel)
        try
            % Try to auto-resize the columns
            methodsObj.tableObj.setRowAutoResizes(true);
            jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
            jideTableUtils.autoResizeAllColumns(methodsObj.tableObj);
        catch
            % JIDE is probably unavailable - never mind...
        end

        % Disable editing
        %methodsObj.tableObj.setEnabled(0);
        cbNameTextField = javax.swing.JTextField;
        cbNameTextField.setEditable(false);  % ensure that the method names are not modified...
        cbNameCellEditor = javax.swing.DefaultCellEditor(cbNameTextField);
        cbNameCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
        for colIdx = 1:length(headers)
            methodsObj.tableObj.getColumnModel.getColumn(colIdx-1).setCellEditor(cbNameCellEditor);
        end
    catch
        % Never mind...
        %disp(lasterr);  rethrow(lasterror)
    end
%end  % updateMethodsTable

%% Update the properties table following a checkbox modification
function updatePropsTable(src, evd, varargin)  %#ok partially unused
    try
        % Update callbacks table data according to the modified checkbox state
        propsTable = get(src,'userdata');
        ud = get(propsTable, 'userdata');
        obj = ud.obj;
        inspectorTable = ud.inspectorTable;
        oldData = {};
        try
            oldData = cellfun(@(c)(c.toArray.cell),propsTable.getModel.getActualModel.getDataVector.toArray.cell,'un',0);
        catch
            try
                oldData = cellfun(@(c)(c.toArray.cell),propsTable.getModel.getDataVector.toArray.cell,'un',0);
            catch
                % never mind...
            end
        end
        oldData = [oldData{:}]';
		if ~isfield(ud,'cbInspected'),  ud.cbInspected.isSelected = true;  end
        [propData, propHeaders] = getPropsData(obj, ud.cbMetaData.isSelected, ud.cbInspected.isSelected, inspectorTable, ud.cbInspected);
        if ~isequal(oldData,propData)
            propsTableModel = javax.swing.table.DefaultTableModel(propData,propHeaders);
            try
                ud.obj = handle(obj,'CallbackProperties');
            catch
                try
                    ud.obj = handle(obj);
                catch
                    % never mind...
                end
            end
            ud.inspectorTable = inspectorTable;
            set(propsTableModel, 'TableChangedCallback',@tbPropChanged, 'UserData',ud);
            propsTable.setModel(propsTableModel)
            try
                % Try to auto-resize the columns
                propsTable.setRowAutoResizes(true);
                jideTableUtils = eval('com.jidesoft.grid.TableUtils;');  % prevent JIDE alert by run-time (not load-time) evaluation
                jideTableUtils.autoResizeAllColumns(propsTable);
            catch
                % JIDE is probably unavailable - never mind...
            end
        end

        % Update the header label
		if ~isempty(inspectorTable)
			if ud.cbInspected.isSelected
				set(ud.othersLabel,'Text',' All properties', 'ToolTipText','All properties (including those shown above)');
			else
				set(ud.othersLabel,'Text',' Other properties', 'ToolTipText','Properties not inspectable by the inspect table above');
			end
		end

        % Disable editing all columns except the property Value
        import javax.swing.*
        propTextField = JTextField;
        propTextField.setEditable(false);  % ensure that the prop names & meta-data are not modified...
        propCellEditor = DefaultCellEditor(propTextField);
        propCellEditor.setClickCountToStart(intmax);  % i.e, never enter edit mode...
        for colIdx = 0 : propsTable.getColumnModel.getColumnCount-1
            thisColumn = propsTable.getColumnModel.getColumn(colIdx);
            if ~strcmp(thisColumn.getHeaderValue,'Value')
                thisColumn.setCellEditor(propCellEditor);
            end
        end
    catch
        % Never mind...
        disp(lasterr);  rethrow(lasterror)
    end
%end  % updatePropsTable

%% Update component callback upon callbacksTable data change
function tbCallbacksChanged(src, evd)
    try
        % exit if invalid handle or already in Callback
        if ~ishandle(src) || ~isempty(getappdata(src,'inCallback')) % || length(dbstack)>1  %exit also if not called from user action
            return;
        end
        setappdata(src,'inCallback',1);  % used to prevent endless recursion

        % Update the object's callback with the modified value
        modifiedColIdx = evd.getColumn;
        modifiedRowIdx = evd.getFirstRow;
        if modifiedColIdx==1 && modifiedRowIdx>=0  %sanity check - should always be true
            table = evd.getSource;
            object = get(src,'userdata');
            cbName = strtrim(table.getValueAt(modifiedRowIdx,0));
            try
                cbValue = strtrim(char(table.getValueAt(modifiedRowIdx,1)));
                if ~isempty(cbValue) && ismember(cbValue(1),'{[@''')
                    cbValue = eval(cbValue);
                end
                if (~ischar(cbValue) && ~isa(cbValue, 'function_handle') && (iscom(object(1)) || iscell(cbValue)))
                    revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, '');
                else
                    for objIdx = 1 : length(object)
                        if ~iscom(object(objIdx))
                            try
                                set(object(objIdx), cbName, cbValue);
                            catch
                                set(handle(object(objIdx),'CallbackProperties'), cbName, cbValue);
                            end
                        else
                            cbs = object(objIdx).eventlisteners;
                            if ~isempty(cbs)
                                cbs = cbs(strcmpi(cbs(:,1),cbName),:);
                                object(objIdx).unregisterevent(cbs);
                            end
                            if ~isempty(cbValue)
                                object(objIdx).registerevent({cbName, cbValue});
                            end
                        end
                    end
                end
            catch
                revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, lasterr)
            end
        end
    catch
        % never mind...
    end
    setappdata(src,'inCallback',[]);  % used to prevent endless recursion
%end  % tbCallbacksChanged

%% Revert Callback table modification
function revertCbTableModification(table, modifiedRowIdx, modifiedColIdx, cbName, object, errMsg)  %#ok
    try
        % Display a notification MsgBox
        msg = 'Callbacks must be a ''string'', or a @function handle';
        if ~iscom(object(1)),  msg = [msg ' or a {@func,args...} construct'];  end
        if ~isempty(errMsg),  msg = {errMsg, '', msg};  end
        msgbox(msg, ['Error setting ' cbName ' callback'], 'warn');

        % Revert to the current value
        curValue = '';
        try
            if ~iscom(object(1))
                curValue = charizeData(get(object(1),cbName));
            else
                cbs = object(1).eventlisteners;
                if ~isempty(cbs)
                    cbs = cbs(strcmpi(cbs(:,1),cbName),:);
                    curValue = charizeData(cbs(1,2));
                end
            end
        catch
            % never mind... - clear the current value
        end
        table.setValueAt(curValue, modifiedRowIdx, modifiedColIdx);
        pause(0.05);  % enable the table change to register and the callback to be ignored
    catch
        % never mind...
    end
%end  % revertCbTableModification

%% Hyperlink to new uiinspector upon table hyperlink change
function tbMousePressed(src, evd)
    % exit if invalid handle
    if ~ishandle(src)  % || length(dbstack)>1  %exit also if not called from user action
        return;
    end

    try
        tableObj = evd.getComponent;  % =src.java
        selectedRowIdx    = tableObj.getSelectedRow;
        selectedColumnIdx = tableObj.getSelectedColumn;
        cellData = char(tableObj.getValueAt(selectedRowIdx,selectedColumnIdx));
        [a,b,c,d,e] = regexp(cellData,'">([^<]*)</a>');  %#ok a-d are unused
        classes = unique([e{:}]);
        if iscell(classes)
            cellfun(@uiinspect,classes);
        elseif ~isempty(classes)
            uiinspect(classes)
        end
    catch
        % never mind...
    end
%end  % tbMousePressed

%% Update pointer to hand over hyperlinks
function tbMouseMoved(src, evd)
    % exit if invalid handle
    if ~ishandle(src)  % || length(dbstack)>1  %exit also if not called from user action
        return;
    end

    try
        tableObj = evd.getComponent;  % =src.java
        point = java.awt.Point(evd.getX, evd.getY);
        selectedRowIdx    = tableObj.originalRowAtPoint(point);
        selectedColumnIdx = tableObj.originalColumnAtPoint(point);
        cellData = char(tableObj.getValueAt(selectedRowIdx,selectedColumnIdx));
        if isempty(strfind(cellData,'</a>'))
            tableObj.setCursor([]);
        else
            tableObj.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));
        end
    catch
        % never mind...
        %lasterr
    end
%end  % tbMouseMoved

%% Update component property upon properties table data change
function tbPropChanged(src, evd)
    % exit if invalid handle
    if ~ishandle(src)  % || length(dbstack)>1  %exit also if not called from user action
        return;
    end

    % Update the object's property with the modified value
    modifiedColIdx = evd.getColumn;
    modifiedRowIdx = evd.getFirstRow;
    if modifiedRowIdx>=0  %sanity check - should always be true
        table = evd.getSource;
        ud = get(src,'userdata');
        object = ud.obj;
        inspectorTable = ud.inspectorTable;
        propName = strtrim(table.getValueAt(modifiedRowIdx,0));
        propName = strrep(propName,'<html><font color="#C0C0C0"><i>','');
        propName = strrep(propName,'<html><font color="red"><i>','');
        try
            propValue = strtrim(table.getValueAt(modifiedRowIdx,modifiedColIdx));
            if ~isempty(propValue) && ismember(propValue(1),'{[@''')
                propValue = eval(propValue);
            end
            for objIdx = 1 : length(object)
                set(object(objIdx), propName, propValue);
            end
        catch
            msg = {lasterr, '', ...
                   'Values are interpreted as strings except if enclosed by square brackets [] or curly braces {}', ...
                   '', 'Even simple boolean/numeric values need to be enclosed within [] brackets', ...
                   'For example: [0] or: [pi]'};
            msgbox(msg,['Error setting ' propName ' property'],'error');
            try
                % Revert to the current value (temporarily disable this callback to prevent recursion)
                curValue = charizeData(get(object(1),propName));
                set(table, 'TableChangedCallback',[]);
                table.setValueAt(curValue, modifiedRowIdx, modifiedColIdx);
                set(table, 'TableChangedCallback',@tbPropChanged);
            catch
                % never mind...
            end
        end
        %pause(0.2); awtinvoke(inspectorTable,'repaint(J)',2000);  % not good enough...
        start(timer('TimerFcn',{@repaintInspector,inspectorTable},'StartDelay',2));
    end
%end  % tbPropChanged

%% Repaint inspectorTable following a property modification
function repaintInspector(timerObj, timerData, inspectorTable)  %#ok partially unused
    inspectorTable.repaint;
%end % repaintInspector

%% Get an HTML representation of the object's properties
function dataFieldsStr = getPropsHtml(obj, dataFields)
    try
        % Get a text representation of the fieldnames & values
        undefinedStr = '';
        dataFieldsStr = '';  % just in case the following croaks...
        if isempty(dataFields)
            return;
        end
        dataFieldsStr = evalc('disp(dataFields)');
        if dataFieldsStr(end)==char(10),  dataFieldsStr=dataFieldsStr(1:end-1);  end

        % Strip out callbacks
        dataFieldsStr = regexprep(dataFieldsStr,'^\s*\w*Callback(Data)?:[^\n]*$','','lineanchors');
        dataFieldsStr = regexprep(dataFieldsStr,'\n\n','\n');

        % HTMLize tooltip data
        % First, set the fields' font based on its read-write status
        try
            % ensure this is a Matlab handle, not a java object
            obj = handle(obj, 'CallbackProperties');
        catch
            try
                % HG handles don't allow CallbackProperties...
                obj = handle(obj);
            catch
                % Some Matlab class objects simply cannot be converted into a handle()
            end
        end
        fieldNames = fieldnames(dataFields);
        for fieldIdx = 1 : length(fieldNames)
            thisFieldName = fieldNames{fieldIdx};
            try
                accessFlags = get(findprop(obj,thisFieldName),'AccessFlags');
            catch
                accessFlags = [];
            end
            if isfield(accessFlags,'PublicSet') && strcmp(accessFlags.PublicSet,'on')
                % Bolden read/write fields
                thisFieldFormat = ['<b>' thisFieldName '<b>:$2'];
            elseif ~isfield(accessFlags,'PublicSet')
                % Undefined - probably a Matlab-defined field of com.mathworks.hg.peer.FigureFrameProxy...
                thisFieldFormat = ['<font color="blue">' thisFieldName '</font>:$2'];
                undefinedStr = ', <font color="blue">undefined</font>';
            else % PublicSet=='off'
                % Gray-out & italicize any read-only fields
                thisFieldFormat = ['<font color="#C0C0C0"><i>' thisFieldName '</i></font>:<font color="#C0C0C0"><i>$2<i></font>'];
            end
            dataFieldsStr = regexprep(dataFieldsStr, ['([\s\n])' thisFieldName ':([^\n]*)'], ['$1' thisFieldFormat]);
        end
    catch
        % never mind... - probably an ambiguous property name
        disp(lasterr);  rethrow(lasterror)
    end

    try
        % Method 1: simple <br> list
        %dataFieldsStr = strrep(dataFieldsStr,char(10),'&nbsp;<br>&nbsp;&nbsp;');

        % Method 2: 2x2-column <table>
        dataFieldsStr = regexprep(dataFieldsStr, '^\s*([^:]+:)([^\n]*)\n^\s*([^:]+:)([^\n]*)$', '<tr><td>&nbsp;$1</td><td>&nbsp;$2</td><td>&nbsp;&nbsp;&nbsp;&nbsp;$3</td><td>&nbsp;$4&nbsp;</td></tr>', 'lineanchors');
        dataFieldsStr = regexprep(dataFieldsStr, '^[^<]\s*([^:]+:)([^\n]*)$', '<tr><td>&nbsp;$1</td><td>&nbsp;$2</td><td>&nbsp;</td><td>&nbsp;</td></tr>', 'lineanchors');
        dataFieldsStr = ['(<b>modifiable</b>' undefinedStr ' &amp; <font color="#C0C0C0"><i>read-only</i></font> fields)<p>&nbsp;&nbsp;<table cellpadding="0" cellspacing="0">' dataFieldsStr '</table>'];
    catch
        % never mind - bail out (Maybe matlab 6 that does not support regexprep?)
        disp(lasterr);  rethrow(lasterror)
    end
%end  % getPropsHtml

%% Update tooltip string with an object's properties data
function dataFields = updateObjTooltip(obj, uiObject)
    try
        if ischar(obj)
            toolTipStr = obj;
        else
            toolTipStr = builtin('class',obj);
        end
        dataFields = struct;  % empty struct
        dataFieldsStr = '';
        hgStr = '';

        % Add HG annotation if relevant
        if ishghandle(obj)
            hgStr = ' HG Handle';
        end

        % Note: don't bulk-get because (1) not all properties are returned & (2) some properties cause a Java exception
        % Note2: the classhandle approach does not enable access to user-defined schema.props
        ch = classhandle(handle(obj));
        dataFields = [];
        [sortedNames, sortedIdx] = sort(get(ch.Properties,'Name'));
        for idx = 1 : length(sortedIdx)
            sp = ch.Properties(sortedIdx(idx));
            % TODO: some fields (see EOL comment below) generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run
            if strcmp(sp.AccessFlags.PublicGet,'on') % && ~any(strcmp(sp.Name,{'FixedColors','ListboxTop','Extent'}))
                try
                    dataFields.(sp.Name) = get(obj, sp.Name);
                catch
                    dataFields.(sp.Name) = '<font color="red">Error!</font>';
                end
            else
                dataFields.(sp.Name) = '(no public getter method)';
            end
        end
        dataFieldsStr = getPropsHtml(obj, dataFields);
    catch
        % Probably a non-HG java object
        try
            % Note: the bulk-get approach enables access to user-defined schema-props, but not to some original classhandle Properties...
            dataFields = get(obj);
            dataFieldsStr = getPropsHtml(obj, dataFields);
        catch
            % Probably a missing property getter implementation
            try
                % Inform the user - bail out on error
                err = lasterror;
                if ~ischar(obj)
                    dataFieldsStr = ['<p>' strrep(err.message, char(10), '<br>')];
                else
                    dataFieldsStr = '<p>Cannot inspect fields of class names - only of objects';
                end
            catch
                % forget it...
            end
        end
    end

    % Set the object tooltip
    if ~isempty(dataFieldsStr)
        toolTipStr = ['<html>&nbsp;<b><u><font color="red">' char(toolTipStr) '</font></u></b>' hgStr ':&nbsp;' dataFieldsStr '</html>'];
    end
    uiObject.setToolTipText(toolTipStr);
%end  % updateObjTooltip

%% Check for existence of a newer version
function checkVersion()
    try
        % If the user has not indicated NOT to be informed
        if ~ispref(mfilename,'dontCheckNewerVersion')

            % Get the latest version date from the File Exchange webpage
            baseUrl = 'http://www.mathworks.com/matlabcentral/fileexchange/';
            fexId = '17935';
            webUrl = [baseUrl fexId];  % 'loadFile.do?objectId=' fexId];
            webPage = urlread(webUrl);
            modIdx = strfind(webPage,'>Updates<');
            if ~isempty(modIdx)
                webPage = webPage(modIdx:end);
                % Note: regexp hangs if substr not found, so use strfind instead...
                %latestWebVersion = regexprep(webPage,'.*?>(20[\d-]+)</td>.*','$1');
                dateIdx = strfind(webPage,'class="date">');
                if ~isempty(dateIdx)
                    latestDate = webPage(dateIdx(end)+13 : dateIdx(end)+23);
                    try
                        startIdx = dateIdx(end)+27;
                        descStartIdx = startIdx + strfind(webPage(startIdx:startIdx+999),'<td>');
                        descEndIdx   = startIdx + strfind(webPage(startIdx:startIdx+999),'</td>');
                        descStr = webPage(descStartIdx(1)+3 : descEndIdx(1)-2);
                        descStr = regexprep(descStr,'</?[pP]>','');
                    catch
                        descStr = '';
                    end

                    % Get this file's latest date
                    thisFileName = which(mfilename);  %#ok
                    try
                        thisFileData = dir(thisFileName);
                        try
                            thisFileDatenum = thisFileData.datenum;
                        catch  % old ML versions...
                            thisFileDatenum = datenum(thisFileData.date);
                        end
                    catch
                        thisFileText = evalc('type(thisFileName)');
                        thisFileLatestDate = regexprep(thisFileText,'.*Change log:[\s%]+([\d-]+).*','$1');
                        thisFileDatenum = datenum(thisFileLatestDate,'yyyy-mm-dd');
                    end

                    % If there's a newer version on the File Exchange webpage (allow 2 days grace period)
                    if (thisFileDatenum < datenum(latestDate,'dd mmm yyyy')-2)

                        % Ask the user whether to download the newer version (YES, no, no & don't ask again)
                        msg = {['A newer version (' latestDate ') of ' mfilename ' is available on the MathWorks File Exchange:'], '', ...
                            ['\color{blue}' descStr '\color{black}'], '', ...
                            'Download & install the new version?'};
                        createStruct.Interpreter = 'tex';
                        createStruct.Default = 'Yes';
                        answer = questdlg(msg,mfilename,'Yes','No','No & never ask again',createStruct);
                        switch answer
                            case 'Yes'  % => Yes: download & install newer file
                                try
                                    %fileUrl = [baseUrl '/download.do?objectId=' fexId '&fn=' mfilename '&fe=.m'];
                                    fileUrl = [baseUrl '/' fexId '?controller=file_infos&download=true'];
                                    file = urlread(fileUrl);
                                    file = regexprep(file,[char(13),char(10)],'\n');  %convert to OS-dependent EOL
                                    fid = fopen(thisFileName,'wt');
                                    fprintf(fid,'%s',file);
                                    fclose(fid);
                                catch
                                    % Error downloading: inform the user
                                    msgbox(['Error in downloading: ' lasterr], mfilename, 'warn');
                                    web(webUrl);
                                end
                            case 'No & never ask again'   % => No & don't ask again
                                setpref(mfilename,'dontCheckNewerVersion',1);
                            otherwise
                                % forget it...
                        end
                    end
                end
            else
                % Maybe webpage not fully loaded or changed format - bail out...
            end
        end
    catch
        % Never mind...
    end
%end  % checkVersion

%% Debuggable "quiet" error-handling
function dispError
        err = lasterror;
        msg = err.message;
        for idx = 1 : length(err.stack)
            filename = err.stack(idx).file;
            if ~isempty(regexpi(filename,mfilename))
                funcname = err.stack(idx).name;
                line = num2str(err.stack(idx).line);
                msg = [msg ' at <a href="matlab:opentoline(''' filename ''',' line ');">' funcname ' line #' line '</a>']; %#ok grow
                break;
            end
        end
        disp(msg);
        return;  % debug point
%end  % dispError


%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%
% - Enh: Cleanup internal functions, remove duplicates etc.
% - Enh: link objects to another uiinspect window for these objects
% - Enh: display object children (& link to them) - COM/Java
% - Enh: find a way to merge the other-properties table into the inspector table
% - Fix: enable table sorting
% - Fix: some fields generate a Java Exception from: com.mathworks.mlwidgets.inspector.PropertyRootNode$PropertyListener$1$1.run
% - Fix: Sun javadoc hyperlink for classNames with internal '.'
% - Fix: In HG tree view, sometimes the currently-inspected handle is not selected
