import React, { Component } from "react";

import throttle from "lodash/throttle";
import pathHelper from "path-browserify";

import { SplitPane, ToolbarButton } from "~/base-components/ui-components";

import fileOps from "~/base-components/file-ops";
import CodeEditorCollection from "~/base-components/code-editor";
import FileTree from "~/base-components/filetree";

import WorkspaceContext from "../WorkspaceContext";
import ProjectManager from "../ProjectManager/ProjectManager";
import actions from "../actions";

import contextMenu, { registerHandlers } from "./contextMenu";

import CreateFileOrFolderModals from "./CreateFileOrFolderModals";
import GistUploadModals from "./GistUploadModals";
import RenameModal from "./RenameModal";

const { getSizeUpdate } = SplitPane;
SplitPane.getSizeUpdate = (props, state) => {
  const newState = getSizeUpdate(props, state);
  if (props.adjustSize) {
    newState.pane1Size = props.adjustSize(newState.pane1Size);
    newState.pane2Size = props.adjustSize(newState.pane2Size);
  }
  return newState;
};

export default class Workspace extends Component {
  static contextType = WorkspaceContext;

  constructor(props) {
    super(props);
    this.filetree = React.createRef();
    this.codeEditor = React.createRef();
    this.createModal = React.createRef();
    this.uploadModal = React.createRef();
    this.renameModal = React.createRef();
    this.throttledDispatchResizeEvent = throttle(() => {
      window.dispatchEvent(new Event("resize"));
    }, 200);

    this.updateTree = this.updateTree.bind(this);

    this.state = {
      editorConfig: {},
      showTerminal: !!props.terminal,
      terminalSize: 160,
      expanded: true,
    };

    const effect = ProjectManager.effect("settings:editor", (editorConfig) => {
      this.state.editorConfig = editorConfig;
    });
    this.disposable = effect();

    actions.workspace = this;

    registerHandlers({
      newFile: (node) => this.openCreateFileModal(node),
      newFolder: (node) => this.openCreateFolderModal(node),
      rename: (node) => this.openRenameModal(node),
      deleteFile: (node) => ProjectManager.deleteFile(node),
      openFile: (node) => this.openFile(node, true),
    });
  }

  componentDidMount() {
    const editorConfig = this.context.projectSettings.get("editor");
    this.setState({ editorConfig });
  }

  async componentDidUpdate(prevProps) {
    if (prevProps.terminal !== this.props.terminal) {
      if (this.props.terminal) {
        this.setState({
          showTerminal: true,
          terminalSize: this.state.terminalSize || 160,
        });
      } else {
        this.setState({ showTerminal: false });
      }
      window.dispatchEvent(new Event("resize"));
    }
  }

  componentWillUnmount() {
    this.disposable();
  }

  tabFromPath = (filePath, remote, pathInProject) => ({
    path: filePath,
    key: filePath,
    remote,
    pathInProject,
  });

  setFileTreeActive(path = "") {
    this.filetree.current.setActive(path);
  }

  openFile = ({ path, remote, pathInProject, isLeaf }, setTreeActive) => {
    this.codeEditor.current.openTab(this.tabFromPath(path, remote, pathInProject)); // it triggers onSelectTab function eventually
    path.startsWith("custom:") && this.setFileTreeActive();
    setTreeActive && this.setFileTreeActive(path);
  };

  onSelectTab = (selectedTab) => {
    selectedTab.path && !selectedTab.path.startsWith("custom:")
      ? this.setFileTreeActive(selectedTab.path)
      : this.setFileTreeActive();
  };

  closeAllTabs = () => {};

  updateTree() {
    this.filetree.current && this.filetree.current.updateTreeTitle();
  }

  openCreateFileModal = (node) => {
    const activeNode =
      node || this.filetree.current.activeNode || this.filetree.current.rootNode[0];
    const basePath = activeNode.children ? activeNode.path : pathHelper.dirname(activeNode.path);
    const baseName = basePath;
    this.createModal.current.openCreateFileModal({ baseName, basePath });
  };

  gistUploadFileModal = () => {
    this.uploadModal.current.openModal(
      this.context.projectManager
        ? this.context.projectManager.projectSettings.get("gistId")
        : undefined
    );
  };

  openCreateFolderModal = (node) => {
    const activeNode = node || this.filetree.current.activeNode || this.filetree.current.rootNode;
    const basePath = activeNode.children ? activeNode.path : pathHelper.dirname(activeNode.path);
    const baseName = basePath;
    this.createModal.current.openCreateFolderModal({ baseName, basePath });
  };

  openRenameModal = (node) => {
    const activeNode = node || this.filetree.current.activeNode;
    const type = activeNode.children ? "folder" : "file";
    const { base } = pathHelper.parse(activeNode.path);
    this.renameModal.current.openModal({
      type,
      name: base,
      oldPath: activeNode.path,
    });
  };

  saveAll = async () => {
    const unsavedFiles = this.allUnsavedFiles();
    if (!unsavedFiles.length) {
      return { nSaved: 0 };
    }

    for (let i = 0; i < unsavedFiles.length; i++) {
      const filePath = unsavedFiles[i];
      await this.codeEditor.current.saveFile(filePath);
    }
    return { nSaved: unsavedFiles.length };
  };

  allUnsavedFiles = () => this.codeEditor.current.allUnsavedFiles();

  // fileSaved = (path, saveAsPath) => {
  //   this.codeEditor.current.fileSaved(path, { saveAsPath })
  // }

  onDragTerminal = (size) => {
    if (!this.state.showTerminal) {
      if (this.state.terminalSize < 160) {
        this.setState({ terminalSize: 160 });
      }
      this.context.projectManager.toggleTerminal(true);
    } else if (size < 50) {
      this.context.projectManager.toggleTerminal(false);
      this.setState({ terminalSize: 0 });
    }
  };

  render() {
    const {
      theme,
      initial,
      ProjectToolbar,
      signer,
      Terminal,
      defaultSize,
      readOnly: readOnlyInProps = false,
      makeContextMenu = (x) => x,
      addLanguagesCallback,
    } = this.props;

    const readOnly =
      readOnlyInProps ||
      (!this.context.projectManager.userOwnProject && this.context.projectManager.remote);

    const { editorConfig, showTerminal, terminalSize } = this.state;

    let Editor = null;
    if (Terminal) {
      Editor = (
        <SplitPane
          split="horizontal"
          primary="second"
          size={showTerminal ? terminalSize : 0}
          minSize={0}
          onChange={(terminalSize) => {
            this.setState({ terminalSize });
            this.throttledDispatchResizeEvent();
          }}
          onDragFinished={this.onDragTerminal}
        >
          <CodeEditorCollection
            ref={this.codeEditor}
            key={this.context.projectRoot}
            theme={theme}
            editorConfig={editorConfig}
            initialTab={this.tabFromPath(initial.path, initial.remote, initial.pathInProject)}
            projectRoot={this.context.projectRoot}
            projectManager={this.context.projectManager}
            onSelectTab={this.onSelectTab}
            readOnly={readOnly}
            onChangeDecorations={this.updateTree}
            addLanguagesCallback={addLanguagesCallback}
          />
          {Terminal}
        </SplitPane>
      );
    } else {
      Editor = (
        <CodeEditorCollection
          ref={this.codeEditor}
          key={this.context.projectRoot}
          theme={theme}
          editorConfig={editorConfig}
          initialTab={this.tabFromPath(initial.path, initial.remote, initial.pathInProject)}
          projectRoot={this.context.projectRoot}
          projectManager={this.context.projectManager}
          onSelectTab={this.onSelectTab}
          readOnly={readOnly}
          onChangeDecorations={this.updateTree}
          addLanguagesCallback={addLanguagesCallback}
        />
      );
    }

    return (
      <>
        <SplitPane
          className="ligoide-workspace"
          defaultSize={defaultSize}
          minSize={160}
          onChange={this.throttledDispatchResizeEvent}
          adjustSize={(size) => {
            if (size && Math.abs(size - defaultSize) < 5) {
              return defaultSize;
            }
            return size;
          }}
          style={{ overflow: undefined }}
        >
          <div className="d-flex flex-column align-items-stretch h-100">
            <div className={`d-flex border-bottom-1 ${this.state.expanded ? "flex-column" : ""}`}>
              <ToolbarButton
                id="expand"
                tooltip={this.state.expanded ? "Hide Actions" : "Expand Actions"}
                readOnly={readOnly}
                onClick={() => this.setState({ expanded: !this.state.expanded })}
                isExpanded={this.state.expanded}
              >
                {this.state.expanded ? (
                  <>
                    <span className="mr-2" key="switch-expanded">
                      <span className="fas fa-chevron-down fa-fw" />
                    </span>
                    Actions
                  </>
                ) : (
                  <span key="switch-close">
                    <span className="fas fa-chevron-right fa-fw" />
                  </span>
                )}
              </ToolbarButton>
              <ToolbarButton
                id="new"
                icon="fas fa-plus"
                tooltip="New File"
                readOnly={readOnly}
                onClick={() => this.openCreateFileModal()}
                isExpanded={this.state.expanded}
              />
              <ToolbarButton
                id="gist"
                icon="fab fa-github"
                tooltip="Upload to Gist"
                readOnly={readOnly}
                onClick={() => this.gistUploadFileModal()}
                isExpanded={this.state.expanded}
              />
              <ProjectToolbar
                finalCall={this.updateTree}
                signer={signer}
                editor={this.codeEditor}
                isExpanded={this.state.expanded}
              />
            </div>
            <FileTree
              ref={this.filetree}
              projectManager={this.context.projectManager}
              initialPath={initial.path}
              onSelect={this.openFile}
              readOnly={readOnly}
              contextMenu={makeContextMenu(contextMenu, this.context.projectManager)}
            />
          </div>
          {Editor}
        </SplitPane>
        <CreateFileOrFolderModals
          ref={this.createModal}
          projectManager={this.context.projectManager}
        />
        <GistUploadModals
          ref={this.uploadModal}
          fileTreeRef={this.filetree}
          projectManager={this.context.projectManager}
        />
        <RenameModal ref={this.renameModal} projectManager={this.context.projectManager} />
      </>
    );
  }
}
