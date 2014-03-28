package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	// "runtime/pprof"
	"strings"
	// "fmt"
	"gopkg.in/v0/qml"
)

const (
	DICT_PATH = "./dictionaries"
)

type Control struct {
	Root             qml.Object
	DictionariesList []string
	Len              int
	SearchResult     string
	Busy             bool
}

var ctrl = &Control{}
var busy chan bool

func (c *Control) DictName(i int) string {
	return c.DictionariesList[i]
}

func (c *Control) Search(searchstring string, mode string, active_dicts []string) {
	go func() {
		busy <- true
		c.SearchResult = ""
		spacing := " "
		if mode == "startswith" {
			spacing = ""
		}
		// log.Printf(
		// 	"Active dictionaries: %v\nSearch string: %s\nSearch mode: %s\n",
		// 	active_dicts,
		// 	searchstring,
		// 	mode,
		// )
		for _, d := range active_dicts {
			data, err := ioutil.ReadFile(path.Join(DICT_PATH, d))
			if err != nil {
				log.Fatal(err)
			}
			for _, entry := range strings.Split(string(data), "\n") {
				if strings.HasPrefix(strings.ToLower(entry), searchstring+spacing) {
					// log.Println(entry)
					c.SearchResult += fmt.Sprintf("<b>%s:</b><br />%s<br /><br />", d, entry)
				}
			}
		}
		qml.Changed(c, &c.SearchResult)
		busy <- false
	}()

}

func GetDictList(path string) []string {
	var dict_files []string
	files, err := ioutil.ReadDir(path)
	if err != nil {
		log.Fatal(err)
	}
	for _, f := range files {
		dict_files = append(dict_files, f.Name())
	}
	return dict_files
}

func (c *Control) Load(dictionary string) {
	go func() {
		// log.Println("LOADING", dictionary)
		c.SearchResult = ""
		busy <- true
		data, err := ioutil.ReadFile(path.Join(DICT_PATH, dictionary))
		if err != nil {
			log.Fatal(err)
		}
		c.SearchResult = string(data)
		// log.Println("LOADED!")
		qml.Changed(c, &c.SearchResult)
		busy <- false
	}()
}

func (c *Control) Save(text string, filename string) {
	// log.Println("SAVING! to", filename)
	f, err := os.Create(path.Join(DICT_PATH, filename))
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	_, err = f.WriteString(text)
	if err != nil {
		log.Fatal(err)
	}

}

func main() {

	// Profiling -->
	// f, err := os.Create("cpu.prof")
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// pprof.StartCPUProfile(f)
	// defer pprof.StopCPUProfile()
	// <-- Profiling

	// Watching busy status
	busy = make(chan bool)
	go func() {
		for {
			ctrl.Busy = <-busy
			qml.Changed(ctrl, &ctrl.Busy)
		}
	}()

	qml.Init(nil)
	engine := qml.NewEngine()
	component, err := engine.LoadFile("qmldict.qml")
	if err != nil {
		panic(err)
	}

	ctrl.DictionariesList = GetDictList(DICT_PATH)
	ctrl.Len = len(ctrl.DictionariesList)
	context := engine.Context()
	context.SetVar("ctrl", ctrl)

	// log.Println(ctrl.DictionariesList)

	window := component.CreateWindow(nil)
	ctrl.Root = window.Root()

	window.Show()
	window.Wait()
}
