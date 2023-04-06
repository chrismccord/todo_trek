// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
// import {LiveSocket} from "phoenix_live_view"
import {LiveSocket} from "/Users/chris/oss/phoenix_live_view/assets/js/phoenix_live_view"
import topbar from "../vendor/topbar"
import Sortable from "../vendor/sortable"

let Hooks = {}

let scrollTop = () => {
  return document.documentElement.scrollTop || document.body.scrollTop
}

Hooks.LocalTime = {
  mounted(){ this.updated() },
  updated() {
    let dt = new Date(this.el.textContent)
    let options = {hour: "2-digit", minute: "2-digit", hour12: true, timeZoneName: "short"}
    this.el.textContent = `${dt.toLocaleString('en-US', options)}`
    this.el.classList.remove("invisible")
  }
}

function isElementAt(element, position) {
  const rect = element.getBoundingClientRect()
  const winHeight = (window.innerHeight || document.documentElement.clientHeight)

  if(position === "top"){
    return rect.top >= 0 && rect.left >= 0 && rect.top <= winHeight
  } else if(position === "bottom") {
    return rect.bottom >= 0 && rect.right >= 0 && rect.bottom <= winHeight
  } else {
    throw new Error(`Invalid position. "top" or "bottom" expected, got: ${position}`)
  }
}

Hooks.InfiniteScroll = {
  page() { return parseInt(this.el.dataset.page) },
  mounted(){
    let scrollBefore = scrollTop()
    this.pending = this.page()
    let maxPage = null
    window.addEventListener("scroll", e => {
      let scrollNow = scrollTop()
      let page = this.page()

      if(this.pending !== this.page()){
        scrollBefore = scrollNow
        return
      }

      let lastChild = this.el.lastElementChild
      let firstChild = this.el.firstElementChild
      if(page > 1 && scrollNow < scrollBefore && isElementAt(firstChild, "top")){
        this.pending = page - 1
        this.pushEvent("load-prev-page", {}, () => {
          this.pending = this.page()
          maxPage = null
          firstChild.scrollIntoView({block: "center", inline: "nearest"})
        })
      } else if((!maxPage || page < maxPage) && scrollNow > scrollBefore && isElementAt(lastChild, "bottom")){
        this.pending = page + 1
        this.pushEvent("load-next-page", {}, () => {
          if(this.pending !== this.page()){ maxPage = this.page() }
          this.pending = this.page()
          lastChild.scrollIntoView({block: "center"})
        })
      }
      scrollBefore = scrollNow
    })
  }
}

Hooks.Sortable = {
  mounted(){
    let group = this.el.dataset.group
    let sorter = new Sortable(this.el, {
      group: group ? {name: group, pull: true, put: true} : undefined,
      animation: 150,
      // delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      // forceFallback: true,
      onEnd: e => {
        let params = {old: e.oldIndex, new: e.newIndex, to: e.to.dataset, ...e.item.dataset}
        this.pushEventTo(this.el, this.el.dataset["drop"] || "reposition", params)
      }
    })
  }
}

Hooks.SortableInputsFor = {
  mounted(){
    let group = this.el.dataset.group
    let sorter = new Sortable(this.el, {
      group: group ? {name: group, pull: true, put: true} : undefined,
      animation: 150,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: "[data-handle]",
      forceFallback: true,
      onEnd: e => {
        this.el.closest("form").querySelector("input").dispatchEvent(new Event("input", {bubbles: true}))
      }
    })
  }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
