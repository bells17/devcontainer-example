package hello

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHello(t *testing.T) {
	ret := Hello()
	assert.Equal(t, ret, "Hello, alex")
}
